##
# Контроллер, обрабатывающий подписки пользователей на web push notifications
#
class WebPushSubscriptionsController < ApplicationController
  include ShopFetcher
  before_action :fetch_shop, only: [:create, :unsubscribe]
  before_action :fetch_user, only: [:create, :unsubscribe]

  # Подписка на пуш-уведомления
  # @method POST
  # @param token [String]
  # @param browser [String]
  # @param shop_id [String]
  # @param ssid [String]
  def create
    client = shop.clients.find_or_create_by!(user_id: @user.id)
    token = params[:token]
    browser = params[:browser]
    if IncomingDataTranslator.alphanum?(token) && IncomingDataTranslator.alphanum?(browser)
      client.web_push_token = token
      client.web_push_browser = browser
      client.web_push_enabled = true
      client.save
    end

    render json: {}
  end

  # Отписка от рассылок в один клик
  # @method PATCH
  # @param shop_id [String]
  # @param ssid [String]
  def unsubscribe
    client = shop.clients.find_by!(user_id: @user.id)
    if client
      client.web_push_token = nil
      client.web_push_browser = nil
      client.web_push_enabled = nil
      client.last_web_push_sent_at = nil
      client.save
    end

    render text: 'ok'
  end

  protected

  def fetch_user
    @user = Session.find_by!(code: params[:ssid]).user
  end
end
