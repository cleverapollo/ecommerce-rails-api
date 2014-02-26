class RecommendationsController < ApplicationController
  def get
    extracted_params = Recommendations::ParamsExtractor.extract(params)
    result = Recommendations::Processor.process(extracted_params)
    render json: result
  rescue Recommendations::Error => e
    respond_with_client_error(e)
  end
end
