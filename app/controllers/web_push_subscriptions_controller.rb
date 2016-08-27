##
# Контроллер, обрабатывающий подписки пользователей на web push notifications
#
class WebPushSubscriptionsController < ApplicationController
  include ShopFetcher
  before_action :fetch_shop, only: [:create, :unsubscribe, :send_test, :decline, :safari_webpush, :delete_safari_webpush]
  before_action :fetch_user, only: [:create, :unsubscribe, :send_test, :decline]

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
    if token.present?
      if token[:endpoint].present? && token[:keys].present?
        client.web_push_token = token
        if token[:endpoint] =~ /google.com/
          client.web_push_browser = 'chrome'
        end
        if token[:endpoint] =~ /mozilla.com/
          client.web_push_browser = 'firefox'
        end
      elsif token[:browser] == 'safari'
        client.web_push_token = token
        client.web_push_browser = token[:browser]
      else
        render text: 'Token does not have right format', code: 400
        return
      end
      client.web_push_enabled = true
      client.web_push_subscription_popup_showed = true
      client.accepted_web_push_subscription = true

      client.save
    else
      render text: 'Token does not exsist', code: 400
      return
    end
    render json: {}
  end


  # Пользователь отказался от подписки после просмотра окна подписки.
  # @method POST
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
  # @method POST
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
    message = {
        title: 'Here is a test message',
        body: 'Только сегодня супер распродажа всякой хрени',
        icon: 'https://p.fast.ulmart.ru/p/gen/350/35077/3507709.jpg',
        url: 'https://rees46.com/?recommended_by=web_push_trigger'
    }
    if WebPush::Sender.send client, shop, JSON.generate(message)
      render text: 'Sent.'
    else
      render text: 'Error. See Rollbar'
    end
  end

  def safari_webpush
    logger.info(params)
    logger.info(request.raw_post)

    if params[:type].include?('/v1/devices/') && params[:type].include?('/registrations/web.com.rees46')
      render json: { token:  params[:type].gsub(/(^.+devices\/)(.+)(\/registrations.+)/, '\2')} , status: 200
    elsif params[:type] == '/v1/log'
      render nothing: true, status: 200
    else
      render nothing: true, status: 200
    end
  end

  def delete_safari_webpush
    logger.info(params)
    render text: params[:type]
  end

  def logger
    @@logger ||= Logger.new("#{Rails.root}/log/safari.log")
  end

  protected

  def fetch_user
    @user = Session.find_by!(code: params[:ssid]).user
  end
end
