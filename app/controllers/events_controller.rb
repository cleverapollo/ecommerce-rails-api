class EventsController < ApplicationController
  include ShopFetcher

  before_action :fetch_active_shop
  before_action :extract_legacy_event_name, only: [:push]


  def push

    # Извлекаем данные из входящих параметров
    extracted_params = ActionPush::Params.new(params)
    extracted_params.shop = @shop
    extracted_params = extracted_params.extract

    # Запускаем процессор с извлеченными данными
    ActionPush::Processor.new(extracted_params).process

    # Сообщаем брокеру брошенных корзин RTB
    popunder_urls = case extracted_params.action.to_sym
      when :cart
         Rtb::Broker.new(extracted_params.shop).notify(extracted_params.user, extracted_params.items)
      when :purchase
        Rtb::Broker.new(extracted_params.shop).clear(extracted_params.user)
      when :remove_from_cart
        Rtb::Broker.new(extracted_params.shop).clear(extracted_params.user, extracted_params.items)
    end

    # Popunder disabled temporarily
    respond_with_success
    # if popunder_urls
    #   render json: { status: 'success', url: popunder_urls }
    # else
    #   respond_with_success
    # end

  rescue ActionPush::Error => e
    log_client_error(e)
    respond_with_client_error(e)
  rescue UserFetcher::SessionNotFoundError => e
    respond_with_client_error(e)
  end

  # Отправка значений кастомных аттрибутов пользователей
  def push_attributes
    session = Session.find_by(code: params[:session_id])
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
