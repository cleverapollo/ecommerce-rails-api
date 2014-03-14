class RecommendationsController < ApplicationController
  def get
    extracted_params = Recommendations::Params.extract(params)
    result = Recommendations::Processor.process(extracted_params)
    render json: result
  rescue ArgumentError => e
    respond_with_client_error(e)
  end
end
