require 'spec_helper'

describe InitController do
  describe 'GET init_script' do
    before { @params = {} }

    shared_examples 'an api initializer' do
      before { get :init_script, @params }

      it 'returns init server string' do
        expect(response.body).to match /REES46.initServer\('.+', '#{Rees46.base_url}', (1|2)\);/
      end

      it 'assigns session to @session' do
        expect(assigns(:session)).to eq Session.first!
      end
    end

    shared_examples 'an api initializer with data' do
      context 'with existing session' do
        before { @session = create(:session, user: create(:user)) }

        it 'assigns that session' do
          get :init_script, @params
          expect(assigns(:session)).to eq @session
        end

        it_behaves_like 'an api initializer'
      end

      context 'without existing session' do
        it_behaves_like 'an api initializer'

        it 'assigns useragent to @session.useragent' do
          request.env['HTTP_USER_AGENT'] = sample_useragent

          get :init_script, @params

          expect(assigns(:session).useragent).to eq sample_useragent
        end
      end
    end

    context 'with cookie' do
      before { request.cookies[Rees46.cookie_name] = sample_session_id }

      it_behaves_like 'an api initializer with data'
    end

    context 'with parameter' do
      before { @params = { rees46_session_id: sample_session_id } }

      it_behaves_like 'an api initializer with data'
    end

    context 'with cookie and parameter' do
      before { request.cookies[Rees46.cookie_name] = sample_session_id }
      before { @params = { rees46_session_id: sample_session_id } }

      it_behaves_like 'an api initializer with data'
    end

    context 'without anything' do
      it_behaves_like 'an api initializer'
    end
  end
end
