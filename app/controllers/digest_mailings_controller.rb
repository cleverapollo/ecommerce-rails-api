##
# Контроллер, отвечающий за дайджестные рассылки.
#
class DigestMailingsController < ApplicationController
  include ShopAuthenticator

  # Запустить рассылку.
  def launch
    DigestMailingLaunchWorker.perform_async(params)
    render nothing: true, status: :ok
  end

  # Импортировать аудиторию.
  def audience
    AudienceImportWorker.perform_async(params)
    render nothing: true, status: :ok
  end
end
