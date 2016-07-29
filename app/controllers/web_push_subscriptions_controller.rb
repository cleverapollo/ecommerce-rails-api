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
    begin
      token = JSON.parse(params[:token]).deep_symbolize_keys
    rescue
      render text: 'Invalid JSON data', code: 400
      return
    end
    if token.present? && token[:endpoint].present? && token[:keys].present?
      client.web_push_token = token
      if token[:endpoint] =~ /google.com/
        client.web_push_browser = 'chrome'
      end
      if token[:endpoint] =~ /mozilla.com/
        client.web_push_browser = 'firefox'
      end
      client.web_push_enabled = true
      client.web_push_subscription_popup_showed = true
      client.accepted_web_push_subscription = true
      client.save
    else
      render text: 'Token does not contain endpoint or keys', code: 400
      return
    end
    render json: {}
  end


  # Пользователь отказался от подписки после просмотра окна подписки.
  # @method PATCH
  # @param shop_id [String]
  # @param ssid [String]
  def decline
    client = shop.clients.find_or_create_by!(user_id: @user.id)
    client.web_push_subscription_popup_showed = true
    client.accepted_web_push_subscription = nil
    client.save
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
      # Делаем так, чтобы потом можно было опять показать окно подписки
      client.web_push_subscription_popup_showed = nil
      client.accepted_web_push_subscription = nil
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
      token = eval(client.web_push_token)
      Webpush.payload_send(
          message: JSON.generate({
                                title: 'Here is a test message',
                                body: 'Только сегодня супер распродажа всякой хрени',
                                icon: 'https://p.fast.ulmart.ru/p/gen/350/35077/3507709.jpg',
                                url: 'https://rees46.com/?recommended_by=web_push_trigger'
                            }),
          endpoint: token[:endpoint],
          auth: token[:keys][:auth],
          p256dh: token[:keys][:p256dh],
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
