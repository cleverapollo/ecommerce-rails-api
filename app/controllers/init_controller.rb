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

    # Генерируем уникальный код для сессии
    if cookies['rees46_session_code'].blank?
      cookies['rees46_session_code'] = params[:seance].present? ? params[:seance] : SecureRandom.uuid
    end

    # Строим массив кук, для поиска первой существующей сессии
    session_id = CGI::Cookie::parse(request.env['HTTP_COOKIE'])['rees46_session_id'].uniq
    if session_id.count > 1
      File.open("#{Rails.root}/log/ssid.log", 'a+') {|f| f << "#{Date.current}: #{session_id.join(', ')}\n" }
    end
    ssid = params[params[:v].present? && params[:v] == '3' ? Rees46::SSID_NAME : Rees46::COOKIE_NAME]
    session_id << ssid if ssid.present?

    email = nil
    if params[:user_email].present?
      email = IncomingDataTranslator.email(params[:user_email])
    end

    session = Session.fetch(code: session_id,
                            location: params[:user_location],
                            city: sanitized_header(:city),
                            country: sanitized_header(:country),
                            language: sanitized_header(:language))

    cookies[Rees46::COOKIE_NAME] = {
      value: session.code,
      expires: 1.year.from_now,
      domain: [request.host, ".#{request.domain}"][rand(0..1)]
    }

    # Поиск связки пользователя и магазина
    begin
      # Новая версия, ищем клиента по сессии
      client = Client.find_by(session: session, shop: shop)

      # Поддержка старого метода, пробуем найти юзера, если по сессии не нашли
      if client.nil?
        client = Client.find_by(user: session.user, shop: shop)
      end

      # Пробуем найти по email
      if email.present? && client.nil?
        client = Client.find_by(email: email, shop: shop)
      end

      # Создаем, если не найден
      if client.nil?
        client = Client.create!(session: session, shop: shop, user_id: session.user_id)
      elsif client.session_id.blank?
        client.session_id = session.id
        client.atomic_save!
      end

    rescue ActiveRecord::RecordNotUnique => e
      client = Client.find_by!(session: session, user_id: session.user_id, shop: shop)
    end

    # Указано мыло
    if email.present?
      client.update_email(email)
    end

    # Сохраняем визит
    Actions::Tracker.track_visit(session, shop, cookies['rees46_session_code'], request)

    # Отмечаем источник перехода, если есть
    if params[:from].present? && params[:code].present?
      lead = LeadSourceProcessor.new(params[:from], params[:code]).process

      # Детектим переход из дайджестного письма для карты кликов
      if lead.is_a?(DigestMail) && params[:map].present?
        lead.click_map = [] if lead.click_map.nil?
        lead.click_map << params[:map].to_i
        lead.click_map.uniq!
        lead.atomic_save! if lead.changed?
      end
    end

    session.updated_at = Date.current
    session.atomic_save! if session.changed?

    recommendations = shop.subscription_plans.product_recommendations.active.paid.exists?

    if params[:v] == '3'
      render json: InitServerString.make_v3(shop: shop, session: session, client: client, seance: cookies['rees46_session_code'], recommendations: recommendations)
    else
      render js: InitServerString.make(shop: shop, session: session, client: client, seance: cookies['rees46_session_code'], recommendations: recommendations)
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
