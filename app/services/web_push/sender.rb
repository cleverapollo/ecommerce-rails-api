# Отправляет веб-пуши
# Управляет балансом веб пушей магазина
# Отменяет подписки, если токен невалиден
class WebPush::Sender

  class << self

    # Отправляет уведомление
    # @param client [Client]
    # @param shop [Shop]
    # @param body [JSON]
    # @return Boolean
    def send(client, shop, body)
      return false if client.nil?
      return false if shop.nil? || shop.web_push_balance < 1
      return false if !client.web_push_enabled?

      begin
        token = eval(client.web_push_token)
      rescue
        Rollbar.e "Wrong web push token for client", client: client, token: client.web_push_token
        return false
      end

      begin
        Webpush.payload_send(
            message: body,
            endpoint: token[:endpoint],
            auth: token[:keys][:auth],
            p256dh: token[:keys][:p256dh],
            # api_key: ( token[:endpoint] ~= /\.google.com\// ? Rails.application.secrets.google_cloud_messaging_key : '')
        )
        shop.reduce_web_push_balance!
      rescue Exception => e
        Rollbar.error e
        return false
      end

      true
    end

  end


end