# Отправляет веб-пуши
# Управляет балансом веб пушей магазина
# Отменяет подписки, если токен невалиден
class WebPush::Sender

  class << self

    # Отправляет уведомление
    # @param client [Client]
    # @param shop [Shop]
    # @param message [Hash{title, body, icon, url}]
    # @param safari_pusher [Grocer] Настройки подключения к сафари серверу. Могут использоваться только для отправки сообщений одного магазина.
    # @param test [Boolean] Тестовая отправка?
    # @return Boolean
    def send(client, shop, message, safari_pusher = shop.web_push_subscriptions_settings.safari_config, test = false)
      return false if client.nil?
      return false if shop.nil? || (shop.web_push_balance < 1 || shop.subscription_plans.paid.where(product: ['digest.webpush', 'trigger.webpush']).count < 1)
      return false unless client.web_push_enabled?

      # send message for all tokens
      client.web_push_tokens.each do |web_push_token|
        begin

          # send message
          web_push_token.send_web_push(message, safari_pusher: safari_pusher)

        rescue Webpush::InvalidSubscription => e
          # save response error message
          WebPushTokenError.create(client_id: web_push_token.client_id, shop_id: shop.id, message: { error: e.message, token: web_push_token.token })
          # remove token
          web_push_token.destroy
        rescue Webpush::ResponseError => e
          if e.message.include?('InvalidTokenFormat')
            web_push_token.destroy
          else
            Rollbar.error e, web_push_token
          end
        rescue SocketError => e
          # save response error message
          WebPushTokenError.create(client_id: web_push_token.client_id, shop_id: shop.id, message: { error: e.message, token: web_push_token.token })
          Rollbar.error e, web_push_token
          web_push_token.destroy
        end
      end

      if client.web_push_tokens.count > 0
        # снимаем с баланса, если остался хотябы один токен -> значит сообщение отправлено успешно
        # и если отправка не тестовая
        shop.reduce_web_push_balance! unless test || shop.subscription_plans.paid.where(product: ['digest.webpush', 'trigger.webpush']).count > 0
      else
        # update user subscription when removed all tokens
        client.clear_web_push_subscription!
        return false
      end

      true
    end
  end
end
