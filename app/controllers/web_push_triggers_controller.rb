##
# Контроллер, отвечающий за триггерные веб пуш рассылки.
#
class WebPushTriggersController < ApplicationController
  include ShopAuthenticator

  def send_test

    session = Session.find_by code: params[:ssid]
    client = Client.find_by(shop_id: @shop.id, user_id: session.user_id)

    trigger = "WebPush::Triggers::#{params[:id].camelize}".constantize.new(client)
    trigger.generate_test_data!
    trigger.settings[:subject] = params[:subject]
    trigger.settings[:message] = params[:message]

    message = WebPush::TriggerMessage.new(trigger, client, nil, true)
    message.send

    render nothing: true
  end

end
