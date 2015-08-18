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
                            city: sanitized_header(:city),
                            country: sanitized_header(:country),
                            language: sanitized_header(:language))

    cookies.delete([Rees46::COOKIE_NAME])
    cookies.permanent[Rees46::COOKIE_NAME] = session.code
    cookies[Rees46::COOKIE_NAME] = {
      value: session.code,
      expires: 1.year.from_now
    }

    render js: InitServerString.make(shop: shop, session: session)
  end

  def init_experiment
    render json: cookies
  end
end
