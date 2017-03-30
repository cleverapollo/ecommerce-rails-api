##
# Контроллер, отвечающий за дайджестные рассылки.
#
class DigestMailingsController < ApplicationController
  include ShopAuthenticator

  # Запустить рассылку.
  def launch
    if params['test_email'].present?
      DigestMailingLaunchWorker.set(queue: 'mailing_test').perform_async(params)
    else
      DigestMailingLaunchWorker.perform_async(params)
    end
    render nothing: true, status: :ok
  end
end
