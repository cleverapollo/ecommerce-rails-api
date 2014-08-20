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

    @session = Session.fetch \
                             uniqid: session_id,
                             useragent: user_agent,
                             email: params[:user_email],
                             city: city,
                             country: country,
                             language: language

    shop = Shop.find_by(uniqid: params[:shop_id])

    if shop.blank?
      render(js: 'REES46.log("Магазин не найден");') and return
    end

    cookies.delete([Rees46.cookie_name])
    cookies.permanent[Rees46.cookie_name] = @session.uniqid

    render js: init_server_string(@session, shop)
  end

  private

  def init_server_string(session, shop)
    ab_testing_group = shop.ab_testing? ? session.user.ab_testing_group_in(shop) : 0
    show_promotion = shop.show_promotion? ? 'true' : 'false'

    <<-JS
      REES46.initServer({
        ssid: '#{session.uniqid}',
        baseURL: '#{Rees46.base_url}',
        testingGroup: #{ab_testing_group},
        currency: '#{shop.currency}',
        showPromotion: #{show_promotion}
      });
    JS
  end

  def user_agent
    c = request.env['HTTP_USER_AGENT']
    if c.present?
      StringHelper.encode_and_truncate(c)
    else
      nil
    end
  end

  def city
    c = request.headers['HTTP_CITY']
    if c.present? && c != 'Undefined'
      StringHelper.encode_and_truncate(c)
    else
      nil
    end
  end

  def country
    c = request.headers['HTTP_COUNTRY']
    if c.present? && c != 'Undefined'
      StringHelper.encode_and_truncate(c)
    else
      nil
    end
  end

  def language
    c = request.env['HTTP_ACCEPT_LANGUAGE']
    if c.present?
      StringHelper.encode_and_truncate(c)
    else
      nil
    end
  end
end
