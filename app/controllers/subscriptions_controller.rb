##
# Контроллер, обрабатывающий подписки пользователей на рассылки
#
class SubscriptionsController < ApplicationController
  include ShopFetcher
  before_action :fetch_shop, only: [:create, :subscribe_for_product_available, :subscribe_for_product_price, :showed]
  before_action :fetch_user, only: [:create, :subscribe_for_product_available, :subscribe_for_product_price, :showed]

  # Взаимодействие с окном сбора email
  def create
    client = shop.clients.find_or_create_by!(user_id: @user.id)
    client.email = IncomingDataTranslator.email(params[:email]) if params[:email].present?
    ShopEmail.fetch(shop, client.email) if client.email.present?

    # Если params[:declined] == true, значит пользователь отказался
    client.accepted_subscription = (params[:declined] != true && params[:declined] != 'true')
    client.subscription_popup_showed = true

    begin
      # Находим настроки подписки
      if shop.subscriptions_settings.segment_id.present?
        # Добавляем клиента в указаный сегмент
        client.add_segment(shop.subscriptions_settings.segment_id)
      end
    rescue Exception => e
      Rollbar.error e
    end

    if client.atomic_save && client.email.present? && client.real_accepted_subscription? && @shop.send_confirmation_email_trigger?
      TriggerMailings::Letter.new(client, TriggerMailings::Triggers::DoubleOptIn.new(client)).send
    end

    render json: {}
  end

  # Отписка от рассылок в один клик
  def unsubscribe

    # Пробуем найти email магазина по коду
    shop_email = ShopEmail.find_by(code: params[:code])
    if shop_email.present?
      shop_email.unsubscribe_from(params[:type], false, params[:mail_code])
    end

    redirect_to "#{Rees46.site_url}/mailings/unsubscribed?code=#{params[:code]}&type=#{params[:type]}"
  end

  # Подписка на рассылоки в один клик
  def subscribe

    # Пробуем найти клиента по коду (старая версия)
    client = Client.find_by(code: params[:code])
    if client.present?
      client.unsubscribe_from(params[:type], true)
    end

    # Пробуем найти email магазина по коду
    shop_email = ShopEmail.find_by(code: params[:code])
    if shop_email.present?
      shop_email.unsubscribe_from(params[:type], false, params[:mail_code])
    end

    redirect_to "#{Rees46.site_url}/mailings/subscribed?code=#{params[:code]}&type=#{params[:type]}"
  end

  # Пользователю было показано окно подписки
  def showed
    client = shop.clients.find_or_create_by!(user_id: @user.id)
    client.subscription_popup_showed = true
    client.save
    render json: {}
  end

  # Трекинг открытого письма
  def track
    if params[:code] != 'test'
      entity = Mail(params[:type]).find_by(code: params[:code])
      entity.mark_as_opened! if entity.present?
    end

    data = open("#{Rails.root}/app/assets/images/pixel.png").read
    send_data data, type: 'image/png', disposition: 'inline'
  end


  # Подписывает пользователя на триггер снижения цены на товар
  # Если у пользователя нет емейла или емейл не равен тому, на который подписываемся,
  # то произвести "склеивание" пользователей - вдруг в базе есть уже такой пользователь
  # TODO: перевести на использование respond_with_client_error и кидать 400 в случае любой ошибки
  def subscribe_for_product_price

    # Если в запросе есть емейл
    if email = IncomingDataTranslator.email(params[:email])

      # Если найден требуемый товар
      if params[:item_id].present? && (item = Item.find_by(shop_id: shop.id, uniqid: params[:item_id]))

        # Находим клиента
        client = shop.clients.find_or_create_by!(user_id: @user.id)

        # Устанавливаем клиенту емейл, если не совпадает или отсутствует.
        # Делаем это безопасно - склейкой пользователей
        if !client.email.present? || client.email != email
          @user = UserMerger.merge_by_mail(shop, client, email)
          client = @user.clients.find_by(shop_id: shop.id, email: email)

          # Добавляем в список email магазина
          ShopEmail.fetch(shop, email)
        end

        # Клиент подписывается на триггеры
        client.subscribe_for_triggers!

        # Подписываем пользователя на триггер
        begin
          # notifier = nil
          # notifier = Slack::Notifier.new Rails.application.secrets.slack_notify_key, username: "Shop #{shop.id}", http_options: { open_timeout: 1 } unless SubscribeForProductPrice.where(shop_id: shop.id).exists?
          TriggerMailings::SubscriptionForProduct.subscribe_for_price shop, @user, item, client.location
          # notifier.ping("Just got first subscription for product price. https://rees46.com/shops/#{shop.id}") if !notifier.nil? && Rails.env == 'production'
        rescue TriggerMailings::SubscriptionForProduct::IncorrectMailingSettingsError => e
          render(json: {}, status: 400) and return
        end

      end

    end

    render json: {}
  end


  # Подписывает пользователя на триггер появления товара в наличии
  # Если у пользователя нет емейла или емейл не равен тому, на который подписываемся,
  # то произвести "склеивание" пользователей - вдруг в базе есть уже такой пользователь
  # TODO: перевести на использование respond_with_client_error и кидать 400 в случае любой ошибки
  def subscribe_for_product_available
    # Если в запросе есть емейл
    if email = IncomingDataTranslator.email(params[:email])

      # Если найден требуемый товар
      if params[:item_id].present? && (item = Item.find_by(shop_id: shop.id, uniqid: params[:item_id]))

        # Если товар не в наличии
        unless item.is_available?

          # Находим клиента
          client = shop.clients.find_or_create_by!(user_id: @user.id)

          # Устанавливаем клиенту емейл, если не совпадает или отсутствует.
          # Делаем это безопасно - склейкой пользователей
          if !client.email.present? || client.email != email
            @user = UserMerger.merge_by_mail(shop, client, email)
            client = @user.clients.find_by(shop_id: shop.id, email: email)

            # Добавляем в список email магазина
            ShopEmail.fetch(shop, email)
          end

          # Клиент подписывается на триггеры
          client.subscribe_for_triggers!

          # Подписываем пользователя на триггер
          begin
            # notifier = nil
            # notifier = Slack::Notifier.new Rails.application.secrets.slack_notify_key, username: "Shop #{shop.id}", http_options: { open_timeout: 1 } unless SubscribeForProductAvailable.where(shop_id: shop.id).exists?
            TriggerMailings::SubscriptionForProduct.subscribe_for_available shop, @user, item
            # notifier.ping("Just got first subscription for product available. https://rees46.com/shops/#{shop.id}") if !notifier.nil? && Rails.env == 'production'
          rescue TriggerMailings::SubscriptionForProduct::IncorrectMailingSettingsError => e
            render(json: {}, status: 400) and return
          end

        end

      end

    end

    render json: {}

  end


  protected

  def fetch_user
    @user = Session.find_by_code!(params[:ssid]).user
  end
end
