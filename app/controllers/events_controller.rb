class EventsController < ApplicationController
  def push
    parameters = ActionPush::ParamsExtractor.extract params
    ActionPush::Processor.new(parameters).process

    respond_with_success
  rescue PushEventError => e
    respond_with_client_error(e)
  end
end
