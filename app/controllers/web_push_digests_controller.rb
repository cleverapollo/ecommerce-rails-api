##
# Контроллер, отвечающий за дайджестные веб пуш рассылки.
#
class WebPushDigestsController < ApplicationController
  include ShopAuthenticator

  # Запустить рассылку.
  def launch
    WebPushDigestLaunchWorker.perform_async(params)
    render nothing: true, status: :ok
  end

end
