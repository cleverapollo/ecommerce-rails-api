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
    session_id = cookies[Rees46::COOKIE_NAME] || params[Rees46::COOKIE_NAME]

    session = Session.fetch(code: session_id,
                            useragent: sanitized_header(:user_agent),
                            email: params[:user_email],
                            location: params[:user_location],
                            city: sanitized_header(:city),
                            country: sanitized_header(:country),
                            language: sanitized_header(:language))

    cookies.delete([Rees46::COOKIE_NAME])
    cookies.permanent[Rees46::COOKIE_NAME] = session.code
    cookies[Rees46::COOKIE_NAME] = {
      value: session.code,
      expires: 1.year.from_now
    }

    # Поиск связки пользователя и магазина
    begin
      client = Client.find_or_create_by!(user_id: session.user_id, shop_id: shop.id)
    rescue ActiveRecord::RecordNotUnique => e
      client = Client.find_by!(user_id: session.user_id, shop_id: shop.id)
    end

    render js: InitServerString.make(shop: shop, session: session, client: client)
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
