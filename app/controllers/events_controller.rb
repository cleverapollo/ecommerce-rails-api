class EventsController < ApplicationController
  include ShopFetcher

  before_action :fetch_active_shop
  before_action :extract_legacy_event_name, only: [:push]


  def push

    # Если магазин в ограниченном режиме
    if @shop.restricted?
      raise Finances::Error.new('Your store is in Restricted Mode. Please contact our support team at support@rees46.com')
    end

    # Извлекаем данные из входящих параметров
    extracted_params = ActionPush::Params.new(params)
    extracted_params.shop = @shop
    extracted_params = extracted_params.extract

    # Запускаем процессор с извлеченными данными
    ActionPush::Processor.new(extracted_params).process

    # Сообщаем брокеру брошенных корзин RTB
    case extracted_params.action.to_sym
      when :cart
         Rtb::Broker.new(extracted_params.shop).notify(extracted_params.user, extracted_params.items)
      when :purchase
        Rtb::Broker.new(extracted_params.shop).clear(extracted_params.user)
      when :remove_from_cart
        Rtb::Broker.new(extracted_params.shop).clear(extracted_params.user, extracted_params.items)
    end

    # Трекаем изменение сессии для DS
    if params[:segment1].present? && params[:segment2].present?
      if extracted_params.session.segment.nil?
        extracted_params.session.update segment: [{s1: params[:segment1], s2: params[:segment2], date: Time.now.strftime('%d-%m-%Y %H:%M:%S')}]
      else
        last = extracted_params.session.segment.last
        if last['s1'] != params[:segment1] && last['s2'] != params[:segment2]
          extracted_params.session.segment << {s1: params[:segment1], s2: params[:segment2], date: Time.now.strftime('%d-%m-%Y %H:%M:%S')}
          extracted_params.session.save!

          # Отправляем в слак
          if Rails.env == 'production'
            SlackNotifierWorker.perform_async('DS', "Segment changed for session `<https://rees46.com/admin/clients?code=#{extracted_params.session.code}|#{extracted_params.session.code}>`: `#{last['s2']}` -> `#{params[:segment2]}`. Referer: #{request.referer}. Action: #{extracted_params.action}, recommended_by: #{extracted_params.recommended_by}, order_id: #{extracted_params.order_id}. User-Agent: #{request.user_agent}.", 'https://hooks.slack.com/services/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')
          end
        end
      end
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
