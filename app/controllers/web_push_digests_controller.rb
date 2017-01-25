##
# Контроллер, отвечающий за дайджестные веб пуш рассылки.
#
class WebPushDigestsController < ApplicationController
  include ShopAuthenticator

  # Отправляет тестовое сообщение
  def send_test
    web_push_digest = @shop.web_push_digests.find(params.fetch('id'))

    session = Session.find_by code: params[:ssid]
    client = Client.find_by(shop_id: @shop.id, user_id: session.user_id)

    # Отправляем сообщение
    WebPush::DigestMessage.new(client, web_push_digest, nil, @shop.web_push_subscriptions_settings.safari_config, true).send

    render nothing: true
  end

  # Запустить рассылку.
  def launch
    WebPushDigestLaunchWorker.perform_async(params)
    render nothing: true, status: :ok
  end

end
