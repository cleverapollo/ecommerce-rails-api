class Media::InitMediaController < ApplicationController
  include ActionController::Cookies
  include MediumFetcher
  include SanitizedHeaders

  before_action :fetch_non_restricted_medium

  def init_script
    session_id = cookies[Rees46::COOKIE_NAME] || params[Rees46::COOKIE_NAME]

    binding.pry

    session = Session.fetch(code: session_id,
                            useragent: sanitized_header(:user_agent),
                            # email: params[:user_email],
                            city: sanitized_header(:city),
                            country: sanitized_header(:country),
                            language: sanitized_header(:language))

    cookies.delete([Rees46::COOKIE_NAME])
    cookies.permanent[Rees46::COOKIE_NAME] = session.code
    cookies[Rees46::COOKIE_NAME] = {
      value: session.code,
      expires: 1.year.from_now
    }

    render js: init_server_string
  end

  private

  def init_server_string
    result = "REES46.callback();"
  end
end
