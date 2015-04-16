class EventsController < ApplicationController
  def push

    # Flocktory
    return render(nothing: true) if params[:shop_id] == 'b41c3672ac83144540ac06fe466c3f'

    # Заменяет старый параметр action в запросе на event
    extract_legacy_event_name if params[:event].blank?

    # Деактивированным магазинам ничего не даем – сделать то же самое в init_session
    if Shop.find_by(uniqid: params[:shop_id]).try(:deactivated?)
      render(nothing: true) and return false
    end

    parameters = ActionPush::Params.extract(params)
    ActionPush::Processor.new(parameters).process

    respond_with_success
  rescue ActionPush::Error => e
    log_client_error(e)
    respond_with_client_error(e)
  rescue UserFetcher::SessionNotFoundError => e
    respond_with_client_error(e)
  end

  def push_attributes
    shop = Shop.find_by(uniqid: params[:shop_id])
    return respond_with_client_error('Shop not found') if shop.blank?

    if shop.deactivated?
      render(nothing: true) and return false
    end

    session = Session.find_by(code: params[:session_id])
    return respond_with_client_error('Session not found') if session.blank?

    UserProfile::AttributesProcessor.process(shop, session.user, params[:attributes])

    respond_with_success
  end

  private

    def extract_legacy_event_name
      if request.raw_post.present?
        legacy_event_name = request.raw_post.split('&').select{|s| s.include?('action') }.first
        if legacy_event_name
          params[:event] = legacy_event_name.split('=').last
        end
      end
    end
end
