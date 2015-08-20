require 'rails_helper'

describe Media::RecommendationsController do
  describe 'GET create' do

    let!(:medium) { create(:medium) }
    let!(:user) { create(:user) }
    let!(:session) { create(:session, user: user) }

    context 'session and article exist in DB' do
      before do
        @article = medium.articles.create!(external_id: 'article_test')
        allow(Media::RecommenderService).to receive(:recommendations).and_return([])
        @params = { format: :json, medium_id: medium.uniqid, session_id: session.code, article_id: @article.external_id}
      end

      it 'limit not specified' do
        binding.pry
        get :create, @params

        session_last = Session.last!
        expect(session_last.code).to eq(@session.code)

        article = Article.last!
        expect(article.external_id).to eq(@article.external_id)
      end

      it 'take same session and article?' do

        @params[:limit] = 3
        get :create, @params

        session = Session.last!
        expect(session.code).to eq(@session.code)

        article = Article.last!
        expect(article.external_id).to eq(@article.external_id)
      end

    end

    context 'test result' do
      context 'when articles nonexistent' do
        it 'get nonexistent articles' do
          @params = { format: :json, medium_id: medium.uniqid, session_id: session.code, article_id: 'article_test', limit: 3 }
          allow(Media::RecommenderService).to receive(:recommendations).and_return([1,2])
          expect { get :create, @params }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
      context 'when articles exist' do
        before do
          @article = @medium.articles.create!(external_id: 'article_test')
          @params = { format: :json, medium_id: medium.uniqid, session_id: session.code, article_id: 'article_test', limit: 3 }
          allow(Media::RecommenderService).to receive(:recommendations).and_return([@article.id])
          get :create, @params
        end

        it 'get json' do
          expect(response.content_type).to eq('application/json')
        end

        it 'get real articles' do
          expect(JSON.parse(response.body)[0]['id']).to eq(@article.id)
        end
      end
    end
  end
end
