##
# Контроллер, обрабатывающий подписки пользователей на web push notifications
#
class WebPushSubscriptionsController < ApplicationController
  include ShopFetcher
  before_action :fetch_shop, only: [:create, :send_test, :decline, :safari_webpush, :delete_safari_webpush, :received, :showed]
  before_action :fetch_user, only: [:create, :send_test, :decline, :showed]

  # Подписка на пуш-уведомления
  # @method POST
  # Params:
  #   token [String]
  #   shop_id [String]
  #   ssid [String]
  def create
    client = shop.clients.find_or_create_by!(user_id: @user.id)
    begin
      client.append_web_push_token(params[:token])
      render json: {}
    rescue => e
      render json: {error: e.message}, status: 400
    end
  end

  # Пользователю было показано окно подписки
  def showed
    client = shop.clients.find_or_create_by!(user_id: @user.id)
    client.web_push_subscription_popup_showed = true
    client.save
    render json: {}
  end

  # Пользователь отказался от подписки после просмотра окна подписки.
  # @method POST
  # Params:
  #   shop_id [String]
  #   ssid [String]
  def decline
    client = shop.clients.find_or_create_by!(user_id: @user.id)
    client.web_push_subscription_popup_showed = true
    client.accepted_web_push_subscription = nil
    client.save
    render json: {}
  end

  # Отметка о получении сообщения
  # @method POST
  # Params:
  #   shop_id [String]
  #   url [String]
  def received
    if params[:url].present?
      uri = URI::parse(params[:url])
      if uri
        url_params = URI::decode_www_form(uri.query).to_h
        if url_params
          case url_params['recommended_by']

            when 'web_push_trigger'
              message = WebPushTriggerMessage.find_by code: url_params['rees46_web_push_trigger_code']
              message.update(showed: true) if message && !message.showed?

            when 'web_push_digest'
              message = WebPushDigestMessage.find_by code: url_params['rees46_web_push_digest_code']
              message.update(showed: true) if message && !message.showed?

          end
        end
      end
    end
    render nothing: true
  end

  # Отправка тестового пуша для отладки разработки
  # Params:
  #   shop_id [String]
  #   ssid [String]
  def send_test
    client = shop.clients.find_by!(user_id: @user.id)
    message = {
        title: 'Here is a test message',
        body: 'Только сегодня супер распродажа всякой хрени',
        icon: 'https://p.fast.ulmart.ru/p/gen/350/35077/3507709.jpg',
        url: 'https://rees46.com/?recommended_by=web_push_trigger'
    }
    if WebPush::Sender.send(client, shop, message)
      render text: 'Sent.'
    else
      render text: 'Error. See Rollbar'
    end
  end

  def safari_webpush
    logger.info(params)
    logger.info(request.raw_post)

    if params[:type].include?('/v1/devices/') && params[:type].include?('/registrations/' + shop.web_push_subscriptions_settings.safari_website_push_id)
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
