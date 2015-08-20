require 'rails_helper'

describe Media::MediaActionsController do
  describe 'POST create' do
    context 'when project exists' do
      let!(:medium) { create(:medium) }
      let!(:user) { create(:user) }
      let!(:session) { create(:session, user: user) }
      context 'view event' do

        let(:params) {
          {
            medium_id: medium.uniqid,
            session_id: session.code,
            article_id: 'article_test',
            medium_action_type: 'view',
            url: 'http://example.com'
          }
        }

        it 'creates view Media Action' do
          post :create, params

          article = Article.first!
          expect(article.external_id).to eq(params[:article_id])
          expect(article.medium_id).to eq(medium.id)

          media_action = MediumAction.first!
          expect(media_action.article_id).to eq(article.id)
          expect(media_action.medium_action_type).to eq('view')
          expect(media_action.medium_id).to eq(medium.id)

          session_first = Session.first!
          expect(session_first.code).to eq(params[:session_id])
          expect(media_action.user_id).to eq(session_first.user.id)
        end

        it 'doesnt creates new item if it exists' do
          article = medium.articles.create(external_id: params[:article_id])

          post :create, params
          expect(Article.count).to eq(1)
        end

        # it 'saves an email of session' do
        #   # session = Session.create!(code: @params[:session_id])
        #   params[:email] = 'test@example.com'
        #   post :create, params
        #   expect(session.reload.email).to eq(params[:email])
        # end

        it 'responds with event id' do
          post :create, params

          expect(response.body).to eq(MediumAction.first.id.to_s)
        end
      end

      context 'full view event' do
        it 'creates full_view event' do

          post :create, { medium_id: medium.uniqid, session_id: session.code, article_id: 'item_test', medium_action_type: 'full_view', url: 'http://example.com' }

          article = Article.first!
          expect(article.external_id).to eq('item_test')
          expect(article.medium_id).to eq(medium.id)

          medium_action = MediumAction.first!
          expect(medium_action.article_id).to eq(article.id)
          expect(medium_action.medium_action_type).to eq('full_view')
          expect(medium_action.medium_id).to eq(medium.id)

          session_first = Session.first!
          expect(medium_action.user_id).to eq(session.user.id)
        end
      end
    end

    context 'when medium does not exist' do
      it 'responds with 403' do
        post :create, { medium_id: 'project_test', session_id: 'session_test', article_id: 'item_test', event_type: 'view', url: 'http://example.com' }
        expect(response.status).to eq(403)
      end
    end
  end
end
