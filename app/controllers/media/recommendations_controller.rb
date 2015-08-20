class Media::RecommendationsController < ApplicationController
  include MediumFetcher

  before_action :fetch_non_restricted_medium

  def create
    # respond_to do |format|
    #   format.json do

        session = Session.find_by!(code: params[:session_id])

        begin
          article = @medium.articles.find_or_create_by!(external_id: params[:article_id])
        rescue ActiveRecord::RecordNotUnique
          article = Article.find_by!(external_id: params[:article_id])
        end

        limit = params[:limit].to_i

        r_params = {
          project_id: @medium.id,
          user_id: session.user.id,
          items: article.id,
          limit: limit
        }
        ids = Media::RecommenderService.recommendations(r_params)

        json_items = ids.map { |article_id|
          article = Article.select(:id, :title, :url, :image).find(article_id)
          article.url = "#{article.url}?recommended_by=content"
          article
        }.to_json
        render json: json_items
    #   end
    # end
  end
end
