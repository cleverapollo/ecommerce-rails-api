class RecommendationsController < ApplicationController
  def get
    render json: $brb.recommend_block(155).to_s
  end
end
