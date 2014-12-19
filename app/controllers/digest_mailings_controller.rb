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

  # Запрос рекомендаций.
  def recommendations
    if params[:email].blank?
      respond_with_client_error('E-mail is undefined') and return false
    end

    if params[:mode].blank?
      params[:mode] = :user_shop_relations
    end

    DigestMailingRecommendationsCalculatorWorker.perform_async(params)
    render text: 'OK'
  end
end
