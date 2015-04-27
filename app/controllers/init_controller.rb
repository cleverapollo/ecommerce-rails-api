class InitController < ApplicationController
  include ActionController::Cookies

  # Генерирует сессию нового покупателя для магазина.
  # Используется в Server SDK или Mobile SDK, где невозможно использовать наш JS SDK.
  def generate_ssid
    shop = Shop.find_by(uniqid: params[:shop_id])
    if shop.present? && shop.active?
      render text: Session.fetch.code
    else
      # Не генерируем сессию для деактивированных магазинов
      render nothing: true
    end
  end

  # Скрипт инициализации покупателя.
  # Определяет покупателя, сращивает разных покупателей в один, если необходимо.
  # Передает магазину данные о текущих свойствах клиента: группа, настройки сбора емейла и рассылок.
  def init_script
    session_id = cookies[Rees46.cookie_name] || params[Rees46.cookie_name]

    shop = Shop.find_by(uniqid: params[:shop_id])

    if shop.blank?
      render(js: 'REES46._log("Магазин не найден");') and return
    end

    if shop.deactivated?
      render(nothing: true) and return false
    end

    @session = Session.fetch(code: session_id,
                             useragent: user_agent,
                             email: params[:user_email],
                             city: city,
                             country: country,
                             language: language)

    cookies.delete([Rees46.cookie_name])
    cookies.permanent[Rees46.cookie_name] = @session.code
    cookies[Rees46.cookie_name] = {
      value: @session.code,
      expires: 1.year.from_now
    }

    render js: init_server_string(@session, shop)
  end

  private

  # Шаблон JS-кода, который отдается магазину при инициализации покупателя
  # @param session
  # @param shop
  # @return string
  def init_server_string(session, shop)
    result  = "REES46.initServer({"
    result += "  ssid: '#{session.code}',"
    result += "  baseURL: 'http://#{Rees46.host}',"
    result += "  testingGroup: #{shop.ab_testing? ? session.user.ab_testing_group_in(shop) : 0},"
    result += "  currency: '#{shop.currency}',"
    result += "  showPromotion: #{shop.show_promotion? ? 'true' : 'false'},"

    # Поиск связки пользователя и магазина
    s_u = begin
      shop.clients.find_or_create_by!(user_id: session.user_id)
    rescue ActiveRecord::RecordNotUnique => e
      shop.clients.find_by!(user_id: session.user_id)
    end

    # Настройки сбора e-mail
    result += "  subscriptions: {"
    if shop.subscriptions_enabled? && s_u.email.blank?
      result += "  settings: #{shop.subscriptions_settings.to_json}, "
      if shop.subscriptions_settings.has_picture?
         result += "  picture_url: '#{shop.subscriptions_settings.picture_url}',"
      end
      result += "  user: {"
      result += "    declined: #{s_u.subscription_popup_showed == true && s_u.accepted_subscription == false}"
      result += "  }"
    end
    result += "  }"

    result += "});"
    result
  end

  def user_agent
    sanitize_header(request.env['HTTP_USER_AGENT'])
  end

  # Определяются в NGINX через базу GeoIP
  def city
    sanitize_header(request.headers['HTTP_CITY'])
  end

  # Определяются в NGINX через базу GeoIP
  def country
    sanitize_header(request.headers['HTTP_COUNTRY'])
  end

  def language
    sanitize_header(request.env['HTTP_ACCEPT_LANGUAGE'])
  end

  def sanitize_header(value)
    if value.present? && value != 'Undefined'
      StringHelper.encode_and_truncate(value)
    end
  end
end
