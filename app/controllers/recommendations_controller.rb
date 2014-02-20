class RecommendationsController < ApplicationController
  def get
    render json: BrbService.recommend(155)
  end
end
