##
# Контроллер, отвечающий за триггерные веб пуш рассылки.
#
class WebPushTriggersController < ApplicationController
  include ShopAuthenticator

  def send_test
    # todo тестовый триггер отправляется с мастера. Убираем, потому, что тестовые триггеры шлются как от магазина REES46
    raise NotImplementedError

    session = Session.find_by_code(params[:ssid])
    client = Client.find_by(shop_id: @shop.id, user_id: session.user_id)

    trigger = "WebPush::Triggers::#{params[:id].camelize}".constantize.new(client)
    trigger.generate_test_data!
    trigger.settings[:subject] = params[:subject]
    trigger.settings[:message] = params[:message]

    message = WebPush::TriggerMessage.new(trigger, client, @shop.web_push_subscriptions_settings.safari_config, true)
    message.send

    render nothing: true
  end

end
