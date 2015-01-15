class InitController < ApplicationController
  include ActionController::Cookies

  def generate_ssid
    if Shop.find_by(uniqid: params[:shop_id]).present?
      render text: Session.fetch.uniqid
    else
      render nothing: true
    end
  end

  def init_script
    session_id = cookies[Rees46.cookie_name] || params[Rees46.cookie_name]

    @session = Session.fetch(code: session_id,
                             useragent: user_agent,
                             email: params[:user_email],
                             city: city,
                             country: country,
                             language: language)

    shop = Shop.find_by(uniqid: params[:shop_id])

    if shop.blank?
      render(js: 'REES46._log("Магазин не найден");') and return
    end

    cookies.delete([Rees46.cookie_name])
    cookies.permanent[Rees46.cookie_name] = @session.code
    cookies[Rees46.cookie_name] = {
      value: @session.code,
      expires: 1.year.from_now
    }

    render js: init_server_string(@session, shop)
  end

  private

  def init_server_string(session, shop)
    result  = "REES46.initServer({"
    result += "  ssid: '#{session.code}',"
    result += "  baseURL: 'http://#{Rees46.host}',"
    result += "  testingGroup: #{shop.ab_testing? ? session.user.ab_testing_group_in(shop) : 0},"
    result += "  currency: '#{shop.currency}',"
    result += "  showPromotion: #{shop.show_promotion? ? 'true' : 'false'},"

    result += "  subscriptions: {"
    # Broken
    # if shop.trigger_mailing.present? && shop.trigger_mailing.enabled
    #   result += "  settings: #{shop.trigger_mailing.subscription_settings},"
    #   if subscription = session.user.subscriptions.find_by(shop: shop)
    #     result += "  user: #{subscription.to_json},"
    #   end
    # end
    result += "  },"

    result += "});"
    result
  end

  def user_agent
    sanitize_header(request.env['HTTP_USER_AGENT'])
  end

  def city
    sanitize_header(request.headers['HTTP_CITY'])
  end

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
