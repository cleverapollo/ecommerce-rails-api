class EventsController < ApplicationController
  include ActionController::Cookies
  include ShopFetcher

  before_action :fetch_active_shop
  before_action :extract_legacy_event_name, only: [:push]


  def push

    # Если магазин в ограниченном режиме
    if @shop.restricted?
      raise Finances::Error.new('Your store is in Restricted Mode. Please contact our support team at desk@rees46.com')
    end

    # Генерируем уникальный код для сессии
    if cookies['rees46_session_code'].blank?
      cookies['rees46_session_code'] = SecureRandom.uuid
    end

    # Извлекаем данные из входящих параметров
    extracted_params = ActionPush::Params.new(params)
    extracted_params.shop = @shop
    extracted_params.current_session_code = cookies['rees46_session_code']
    extracted_params = extracted_params.extract

    # Запускаем процессор с извлеченными данными
    ActionPush::Processor.new(extracted_params).process

    # Сообщаем брокеру брошенных корзин RTB
    case extracted_params.action.to_sym
      when :cart
         Rtb::Broker.new(extracted_params.shop).notify(extracted_params.user, ClientCart.find_by(user_id: extracted_params.user.id, shop_id: extracted_params.shop.id, date: Date.current).try(:items) )
      when :purchase
        Rtb::Broker.new(extracted_params.shop).clear(extracted_params.user)
      when :remove_from_cart
        Rtb::Broker.new(extracted_params.shop).notify(extracted_params.user, ClientCart.find_by(user_id: extracted_params.user.id, shop_id: extracted_params.shop.id, date: Date.current).try(:items) )
    end

    respond_with_success

  rescue Finances::Error => e
    respond_with_payment_error(e)
  rescue ActionPush::Error => e
    log_client_error(e)
    respond_with_client_error(e)
  rescue UserFetcher::SessionNotFoundError => e
    respond_with_client_error(e)
  end

  # Отправка значений кастомных аттрибутов пользователей
  def push_attributes
    session = Session.find_by_code(params[:session_id])
    return respond_with_client_error('Session not found') if session.blank?

    user = session.user
    return respond_with_client_error('User not found for this session') if user.nil?

    UserProfile::AttributesProcessor.process(shop, user, params[:attributes])

    respond_with_success
  end

  private

  # Заменяет старый параметр action в запросе на event
  def extract_legacy_event_name
    if params[:event].blank? && request.raw_post.present?
      legacy_event_name = request.raw_post.split('&').select{|s| s.include?('action') }.first
      if legacy_event_name
        params[:event] = legacy_event_name.split('=').last
      end
    end
  end
end
