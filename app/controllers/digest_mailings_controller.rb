##
# Контроллер, отвечающий за дайджестные рассылки.
#
class DigestMailingsController < ApplicationController
  include ShopAuthenticator

  # Запустить рассылку.
  def launch
    DigestMailingLaunchWorker.new.perform(params)
    render nothing: true, status: :ok
  end
end
