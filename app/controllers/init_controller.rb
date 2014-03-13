class InitController < ApplicationController
  include ActionController::Cookies

  def init_script
    session_id = cookies[Rees46.cookie_name] || params[Rees46.cookie_name]

    @session = Session.fetch(uniqid: session_id, useragent: request.env['HTTP_USER_AGENT'].truncate(250))

    cookies.delete([Rees46.cookie_name])
    cookies.permanent[Rees46.cookie_name] = @session.uniqid

    render js: init_server_string(@session)
  end

  private

  def init_server_string(session)
    "REES46.initServer('#{session.uniqid}', '#{Rees46.base_url}', #{session.user.ab_testing_group});"
  end
end
