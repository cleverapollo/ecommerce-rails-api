class WebPushToken < ActiveRecord::Base
  belongs_to :client
  belongs_to :shop

  serialize :token, HashSerializer

  validates :token, uniqueness: { scope: [:client_id] }, presence: true

  # Send web push message
  # @param message [Hash{title, body, icon, url}]
  # @param safari_pusher [Grocer] Настройки подключения к сафари серверу. Могут использоваться только для отправки сообщений одного магазина.
  def send_web_push(message, safari_pusher: shop.web_push_subscriptions_settings.safari_config)

    if browser == 'safari'

      return false unless shop.web_push_subscriptions_settings.safari_enabled?

      notification = Grocer::SafariNotification.new(
        device_token: token[:token],
        title: message[:title],
        body: message[:body],
        action: 'Read',
        url_args: message[:url].gsub(/^https?:\/\/[^\/]+\//, '')
      )

      safari_pusher.push(notification)

      true
    else

      # attach shop id to message
      message[:shop_id] = shop.uniqid

      Webpush.payload_send(
          message: JSON.generate(message),
          endpoint: token[:endpoint],
          auth: token[:keys][:auth],
          p256dh: token[:keys][:p256dh],
          api_key: ( token[:endpoint].match(/google/) ? Rails.application.secrets.google_cloud_messaging_key : '')
      )
      true
    end
  end

end
