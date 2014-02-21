class EventsController < ApplicationController
  def push
    parameters = PushService.extract_parameters(params)
    PushService.process(parameters)
    respond_with_success
  rescue PushEventError => e
    respond_with_client_error(e)
  end
end
