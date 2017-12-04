##
# Контроллер, отвечающий за дайджестные рассылки.
#
class DigestMailingsController < ApplicationController
  include ShopAuthenticator

  # Запустить рассылку.
  def launch
    if params['test_email'].present?
      Rails.logger.warn "email: #{params['test_email']}, params: #{params.inspect}"
      DigestMailingLaunchWorker.set(queue: 'mailing_test').perform_async(params)
    elsif params['start_at'].present?
      DigestMailingLaunchWorker.perform_at(DateTime.parse(params['start_at']), params)
    else
      DigestMailingLaunchWorker.perform_async(params)
    end
    render nothing: true, status: :ok
  end
end
