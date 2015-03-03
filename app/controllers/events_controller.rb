class EventsController < ApplicationController
  def push
    return respond_with_success if params[:shop_id] == 'b41c3672ac83144540ac06fe466c3f'

    extract_legacy_event_name if params[:event].blank?

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
