class InitController < ApplicationController
  include ActionController::Cookies
  include ShopFetcher
  include SanitizedHeaders

  before_action :fetch_active_shop

  # Генерирует сессию нового покупателя для магазина.
  # Используется в Server SDK или Mobile SDK, где невозможно использовать наш JS SDK.
  def generate_ssid
    render text: Session.fetch.code
  end

  # Скрипт инициализации покупателя.
  # Определяет покупателя, сращивает разных покупателей в один, если необходимо.
  # Передает магазину данные о текущих свойствах клиента: группа, настройки сбора емейла и рассылок.
  def init_script
    if cookies['r46_personalization_opt_out'] == 'optout'
      render json: {opt_out: 'enabled'}
      return
    end

    session_id = params[params[:v].present? && params[:v] == '3' ? Rees46::SSID_NAME : Rees46::COOKIE_NAME] || cookies[Rees46::COOKIE_NAME]

    session = Session.fetch(code: session_id,
                            email: params[:user_email],
                            location: params[:user_location],
                            city: sanitized_header(:city),
                            country: sanitized_header(:country),
                            language: sanitized_header(:language))

    cookies.delete([Rees46::COOKIE_NAME])
    cookies.permanent[Rees46::COOKIE_NAME] = session.code
    cookies[Rees46::COOKIE_NAME] = {
      value: session.code,
      expires: 1.year.from_now,
      domain: ".#{request.domain}"
    }

    # Поиск связки пользователя и магазина
    begin
      client = Client.find_or_create_by!(user_id: session.user_id, shop: shop)
    rescue ActiveRecord::RecordNotUnique => e
      client = Client.find_by!(user_id: session.user_id, shop: shop)
    end

    # Сохраняем визит
    VisitTracker.new(shop).track(session.user)

    # Отмечаем источник перехода, если есть
    if params[:from].present? && params[:code].present?
      LeadSourceProcessor.new(params[:from], params[:code]).process
    end

    # Трекаем изменение сессии для DS
    if params[:segment1].present? && params[:segment2].present?
      if session.segment.nil?
        session.update segment: [{s1: params[:segment1], s2: params[:segment2], date: Time.now.strftime('%d-%m-%Y %H:%M:%S')}]
      else
        last = session.segment.last
        if last['s1'] != params[:segment1] && last['s2'] != params[:segment2]
          session.segment << {s1: params[:segment1], s2: params[:segment2], date: Time.now.strftime('%d-%m-%Y %H:%M:%S')}
          session.save!
          session.segment_changed = true

          # Отправляем в слак
          if Rails.env == 'production'
            SlackNotifierWorker.perform_async('DS', "Segment changed for session `<https://rees46.com/admin/clients?code=#{session.code}|#{session.code}>`: `#{last['s2']}` -> `#{params[:segment2]}`. Referer: #{request.referer}. User-Agent: #{request.user_agent}.", 'https://hooks.slack.com/services/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')
          end
        end
      end
    end

    session.updated_at = Date.current
    session.atomic_save! if session.changed?

    if params[:v] == '3'
      render json: InitServerString.make_v3(shop: shop, session: session, client: client)
    else
      render js: InitServerString.make(shop: shop, session: session, client: client)
    end
  end

  def init_experiment
    render json: cookies[Rees46::COOKIE_NAME]
  end

  # Проверяет валидность shop_id и secret
  def check
    response = { key: 'correct', secret: 'skip' }
    if params[:secret].present?
      if shop.secret != params[:secret]
        response[:secret] = 'invalid'
      else
        response[:secret] = 'correct'
      end
    end
    render json: response
  end

  # Возвращает секретного ключа магазина которого позволит использовать синхронизацию заказов в облачных CMS.
  # Ключ будет использоваться только нами и не предназначен для передачи магазинам.
  # http://y.mkechinov.ru/issue/REES-2751
  def secret
    unless params[:admin_key] == 'y0Gs9P542vZb9h4gTNeQ16cATjXq07DyEz1itaiV4QJ2t4MKkoqJeVTGqDeTXS3i'
      render(nothing: true, status: 400) and return false
    end

    render json: response = { shop_secret: @shop.secret }
  end

end
