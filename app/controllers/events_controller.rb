class EventsController < ApplicationController
  def push
    extract_legacy_event_name if params[:event].blank?
    parameters = ActionPush::ParamsExtractor.extract params
    ActionPush::Processor.new(parameters).process

    respond_with_success
  rescue PushEventError => e
    respond_with_client_error(e)
  end

  private

    def extract_legacy_event_name
      params[:event] = request.raw_post.split('&').select{|s| s.include?('action') }.first.split('=').last
    end
end
