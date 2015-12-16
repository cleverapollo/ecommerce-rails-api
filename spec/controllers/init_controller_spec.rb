require 'rails_helper'

describe InitController do
  describe 'GET generate_ssid' do
    let!(:shop) { create(:shop) }

    context 'when shop_id is correct' do
      it 'creates new session' do
        expect{
          get :generate_ssid, shop_id: shop.uniqid
        }.to change { Session.count }.by(1)
      end

      it 'returns new session code' do
        get :generate_ssid, shop_id: shop.uniqid

        expect(response.body).to eq(Session.first!.code)
      end
    end

    context 'when shop_id is incorrect' do
      it 'returns nothing' do
        get :generate_ssid, shop_id: 'potato'
        expect(response.body).to eq('')
      end
    end
  end

  describe 'GET init_script' do
    let!(:shop) { create(:shop) }
    let!(:init_params) { { shop_id: shop.uniqid } }

    shared_examples 'an api initializer' do
      before { get :init_script, init_params }

      it 'returns init server string' do
        expect(response.body).to match(/REES46.initServer\(\{.+\}\);/m)
      end

      it 'stores session_id to cookies' do
        expect(response.cookies[Rees46::COOKIE_NAME]).to eq Session.first.code
      end
    end

    shared_examples 'an api initializer with data' do
      context 'with existing session' do
        let!(:session) { create(:session, user: create(:user)) }

        it_behaves_like 'an api initializer'
      end

      context 'without existing session' do
        it_behaves_like 'an api initializer'
      end
    end

    context 'with cookie' do
      before { request.cookies[Rees46::COOKIE_NAME] = '12345' }

      it_behaves_like 'an api initializer with data'
    end

    context 'with parameter' do
      before { init_params.merge!(rees46_session_id: '12345') }

      it_behaves_like 'an api initializer with data'
    end

    context 'with cookie and parameter' do
      before { request.cookies[Rees46::COOKIE_NAME] = '12345' }
      before { init_params.merge!(rees46_session_id: '12345') }

      it_behaves_like 'an api initializer with data'
    end

    context 'without anything' do
      it_behaves_like 'an api initializer'
    end
  end
end
