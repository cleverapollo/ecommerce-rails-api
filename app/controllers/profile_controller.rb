# Методы работы с DMP и виртуальными профилями.

class ProfileController < ApplicationController

  include ActionController::Cookies
  include SanitizedHeaders

  # Для работы с Auditorius: трекает посещение сайта-партнера Auditorius и, если есть данные на профиль, редиректит
  # на маркировку юзера с нашей кукой.
  def check

    session_id = cookies[Rees46::COOKIE_NAME] || params[Rees46::COOKIE_NAME]
    if session_id
      session = Session.find_by code: session_id
      if session
        redirect_to "//sync.audtd.com/match/rs?pid=#{session_id}"
        return
      end
    end

    render :nothing => true
  end
end
