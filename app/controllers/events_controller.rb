class EventsController < ApplicationController
  def push
    extract_legacy_event_name if params[:event].blank?

    s = Session.find_by(code: params[:ssid])
    raise UserFetcher::SessionNotFoundError if s.blank?
    s.pushing_lock.lock {
      ActiveRecord::Base.transaction {
        parameters = ActionPush::Params.extract(params)
        ActionPush::Processor.new(parameters).process
      }
    }

    respond_with_success
  rescue Redis::Lock::LockTimeout => e
    log_client_error(e)
    respond_with_client_error(e)
  rescue ActionPush::Error => e
    log_client_error(e)
    respond_with_client_error(e)
  rescue UserFetcher::SessionNotFoundError => e
    respond_with_client_error(e)
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
