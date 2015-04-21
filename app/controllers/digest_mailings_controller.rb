##
# Контроллер, отвечающий за дайджестные рассылки.
#
class DigestMailingsController < ApplicationController
  include ShopAuthenticator

  # Запустить рассылку.
  def launch
    Sidekiq.redis_pool
    DigestMailingLaunchWorker.perform_async(params)
    render nothing: true, status: :ok
  end

  # Запрос рекомендаций.
  def recommendations
    # Broken
    # if params[:email].blank?
    #   respond_with_client_error('E-mail is undefined') and return false
    # end

    # #DigestMailingRecommendationsCalculatorWorker.perform_async(params)
    render text: 'OK'
  end
end
