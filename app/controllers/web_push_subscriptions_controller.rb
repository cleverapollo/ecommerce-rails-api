##
# Контроллер, обрабатывающий подписки пользователей на web push notifications
#
class WebPushSubscriptionsController < ApplicationController
  include ShopFetcher
  before_action :fetch_shop, only: [:create, :unsubscribe, :send_test]
  before_action :fetch_user, only: [:create, :unsubscribe, :send_test]

  # Подписка на пуш-уведомления
  # @method POST
  # @param token [String]
  # @param shop_id [String]
  # @param ssid [String]
  def create
    client = shop.clients.find_or_create_by!(user_id: @user.id)
    token = params[:token]
    if token.present?
      client.web_push_token = token
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


  # Отправка тестового пуша для отладки разработки
  # @param shop_id [String]
  # @param ssid [String]
  def send_test
    client = shop.clients.find_by!(user_id: @user.id)
    if client && client.web_push_token.present?
      token = JSON.parse(client.web_push_token)
      Webpush.payload_send(
          message: "Here is a test message",
          endpoint: token[:endpoint],
          auth: token[:auth],
          p256dh: token[:p256dh],
          api_key: Rails.application.secrets.google_cloud_messaging_key
      )
    else
      render text: 'No token available'
    end
  end



  protected

  def fetch_user
    @user = Session.find_by!(code: params[:ssid]).user
  end
end
