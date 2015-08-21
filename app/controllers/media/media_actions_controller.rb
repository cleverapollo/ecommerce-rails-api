class Media::MediaActionsController < ApplicationController
  include MediumFetcher

  before_action :fetch_medium

  def create
    session = Session.find_by!(code: params[:session_id])
    # session.update(email: params[:email]) if params[:email].present?

    begin
      article = @medium.articles.find_or_create_by!(external_id: params[:article_id])
    rescue ActiveRecord::RecordNotUnique
      article = Article.find_by!(external_id: params[:article_id])
    rescue ActiveRecord::RecordInvalid
      article = Article.find_by!(external_id: params[:article_id])
    end

    begin
      article.update!(article_params)
    rescue PG::CharacterNotInRepertoire
      a_params = article_params
      a_params[:title] = a_params[:title].encode('UTF-8');
      a_params[:description] = a_params[:description].encode('UTF-8');
      article.update!(a_params)
    rescue ActiveRecord::StatementInvalid
      a_params = article_params
      a_params[:title] = a_params[:title].force_encoding('Windows-1251').encode('UTF-8');
      a_params[:description] = a_params[:description].force_encoding('Windows-1251').encode('UTF-8');
      article.update!(a_params)
    end

    media_action = @medium.medium_actions.create!(user: session.user, medium_action_type: params[:medium_action_type], article: article, recommended_by: params[:recommended_by])

    return render(text: media_action.id)
  end

  private

  def article_params
    result = params.permit(:url, :title, :image, :description, :encoding)
    result[:url] = URI.decode(params[:url])
    result
  end
end
