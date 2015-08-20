class Media::RecommendationsController < ApplicationController
  include MediumFetcher

  before_action :fetch_non_restricted_medium

  def create
    binding.pry
    respond_to do |format|
      format.json do

        binding.pry
        session = Session.find_by!(code: params[:session_id])

        binding.pry
        begin
          article = @medium.articles.find_or_create_by!(external_id: params[:article_id])
        rescue ActiveRecord::RecordNotUnique
          article = Article.find_by!(external_id: params[:article_id])
        end

        binding.pry
        limit = params[:limit].to_i

        r_params = {
          project_id: @medium.id,
          user_id: session.user.id,
          items: article.id,
          limit: limit
        }
        binding.pry
        ids = Media::RecommenderService.recommendations(r_params)

        binding.pry
        json_items = ids.map { |article_id|
          article = Article.select(:id, :title, :url, :image).find(article_id)
          article.url = "#{article.url}?recommended_by=content"
          article
        }.to_json
        binding.pry
        render json: json_items
      end
    end
  end
end
