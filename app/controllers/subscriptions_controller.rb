##
# Контроллер, обрабатывающий подписки пользователей на рассылки
#
class SubscriptionsController < ApplicationController
  include ShopFetcher
  before_action :fetch_shop, only: [:create, :subscribe_for_product_available, :subscribe_for_product_price]
  before_action :fetch_user, only: [:create, :subscribe_for_product_available, :subscribe_for_product_price]

  # Взаимодействие с окном сбора email
  def create
    client = shop.clients.find_or_create_by!(user_id: @user.id)

    if email = IncomingDataTranslator.email(params[:email])
      client.email = email
    end

    # Если params[:declined] == true, значит пользователь отказался
    client.accepted_subscription = (params[:declined] != true && params[:declined] != 'true')
    client.subscription_popup_showed = true
    client.save

    render json: {}
  end

  # Отписка от рассылок в один клик
  def unsubscribe
    if client = Client.find_by(code: params[:code])
      client.unsubscribe_from(params[:type])
    end

    render text: 'Вы успешно отписаны от рассылок.'
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
        end

        # Клиент подписывается на триггеры
        client.subscribe_for_triggers!

        # Подписываем пользователя на триггер
        begin
          TriggerMailings::SubscriptionForProduct.subscribe_for_price shop, @user, item, client.location
        rescue TriggerMailings::SubscriptionForProduct::IncorrectMailingSettingsError => e
          render nothing: true, code: 400
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
          end

          # Клиент подписывается на триггеры
          client.subscribe_for_triggers!

          # Подписываем пользователя на триггер
          begin
            TriggerMailings::SubscriptionForProduct.subscribe_for_available shop, @user, item
          rescue TriggerMailings::SubscriptionForProduct::IncorrectMailingSettingsError => e
            render nothing: true, code: 400
          end

        end

      end

    end

    render json: {}

  end


  protected

  def fetch_user
    @user = Session.find_by!(code: params[:ssid]).user
  end
end
