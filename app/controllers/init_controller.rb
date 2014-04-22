class InitController < ApplicationController
  include ActionController::Cookies

  def init_script
    session_id = cookies[Rees46.cookie_name] || params[Rees46.cookie_name]

    @session = Session.fetch \
                             uniqid: session_id,
                             useragent: user_agent,
                             city: request.headers['HTTP_CITY'],
                             country: request.headers['HTTP_COUNTRY'],
                             language: request.env['HTTP_ACCEPT_LANGUAGE']

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
    ab_testing_group = session.user.ab_testing_group_in(shop)
    "REES46.initServer('#{session.uniqid}', '#{Rees46.base_url}', #{ab_testing_group});"
  end

  def user_agent
    if request.env['HTTP_USER_AGENT'].present?
      request.env['HTTP_USER_AGENT'].truncate(250)
    else
      ''
    end
  end
end
