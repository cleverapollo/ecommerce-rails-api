require 'rails_helper'

describe InitController do

  before do
    # Возвращаем структуру ответа из Elastic
    allow_any_instance_of(Elasticsearch::Persistence::Repository::Class).to receive(:find).and_return(People::Profile.new)
  end

  describe 'GET check' do
    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer) }

    context 'do not check secret' do
      it 'generates key and secret' do
        expect(shop.uniqid.present?).to be_truthy
        expect(shop.secret.present?).to be_truthy
      end
      it 'checks shop key' do
        get :check, shop_id: shop.uniqid
        expect(JSON.parse(response.body)).to eq({'key' => 'correct', 'secret' => 'skip'})
      end
      it 'raise error when shop not found' do
        get :check, shop_id: '333'
        expect(response.code).to eq '400'
      end
    end

    context 'check secret' do
      it 'checks wrong secret' do
        get :check, shop_id: shop.uniqid, secret: '333'
        expect(JSON.parse(response.body)).to eq({'key' => 'correct', 'secret' => 'invalid'})
      end
      it 'checks correct secret' do
        get :check, shop_id: shop.uniqid, secret: shop.secret
        expect(JSON.parse(response.body)).to eq({'key' => 'correct', 'secret' => 'correct'})
      end
    end

  end


  describe 'GET generate_ssid' do
    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer) }

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
    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer) }
    let!(:init_params) { { shop_id: shop.uniqid } }

    shared_examples 'an api initializer' do
      before { get :init_script, init_params }

      it 'returns init server string' do
        expect(response.body).to match(/REES46.initServer\(\{.+\}\);/m)
      end

      it 'stores session_id to cookies' do
        expect(response.cookies[Rees46::COOKIE_NAME]).to eq Session.first.code
      end

      it 'shop save js sdk v2' do
        expect(shop.reload.js_sdk).to eq(2)
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
      before {
        request.env['HTTP_COOKIE'] = "#{Rees46::COOKIE_NAME}=67890; #{Rees46::COOKIE_NAME}=12345"
      }

      it_behaves_like 'an api initializer with data'
    end

    context 'with parameter' do
      before { init_params.merge!(rees46_session_id: '12345') }

      it_behaves_like 'an api initializer with data'
    end

    context 'with cookie and parameter' do
      before {
        request.env['HTTP_COOKIE'] = "#{Rees46::COOKIE_NAME}=12345"
      }
      before { init_params.merge!(rees46_session_id: '12345') }

      it_behaves_like 'an api initializer with data'
    end

    context 'without anything' do
      it_behaves_like 'an api initializer'
    end
  end


  describe 'GET init_script V3' do

    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer) }
    let!(:init_params) { { shop_id: shop.uniqid, v: 3 } }
    let!(:experiment_1) { create(:experiment, shop_id: shop.id, segments: 2, active: true ) }
    let!(:experiment_2) { create(:experiment, shop_id: shop.id, segments: 3, active: true ) }

    shared_examples 'an api initializer' do
      before { get :init_script, init_params }

      it 'returns init server string' do
        expect(response.body).to match(/\{"ssid":.*\}/m)
      end

      it 'stores session_id to cookies' do
        expect(response.cookies[Rees46::COOKIE_NAME]).to eq Session.first.code
      end

      it 'client link with session' do
        expect(Client.first.session_id).to eq(Session.first.id)
      end

      it 'shop save js sdk v3' do
        expect(shop.reload.js_sdk).to eq(3)
      end

      it 'returns experiments' do
        puts response.body
        expect(JSON.parse(response.body)['experiments'].count).to eq 2
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

    context 'with recommendations plans' do
      let!(:subscription_plan) { create(:subscription_plan, shop: shop, product: 'product.recommendations', paid_till: 1.day.from_now, price: 1) }
      it 'exists' do
        get :init_script, init_params
        expect(JSON.parse(response.body)['recommendations']).to be_truthy
      end
    end

    context 'with cookie' do
      before {
        request.env['HTTP_COOKIE'] = "#{Rees46::COOKIE_NAME}=12345; #{Rees46::COOKIE_NAME}=12345"
      }

      it_behaves_like 'an api initializer with data'
    end

    context 'with parameter' do
      before { init_params.merge!(ssid: '12345') }

      it_behaves_like 'an api initializer with data'
    end

    context 'with cookie and parameter' do
      before {
        request.env['HTTP_COOKIE'] = "#{Rees46::COOKIE_NAME}=12345"
      }
      before { init_params.merge!(ssid: '12345') }

      it_behaves_like 'an api initializer with data'
    end

    context 'without anything' do
      it_behaves_like 'an api initializer'
    end

    context 'user profile' do
      let!(:customer) { create(:customer) }
      let!(:shop) { create(:shop, customer: customer) }
      let!(:user) { create(:user) }
      let!(:session) { create(:session, user: user) }
      let!(:client) { create(:client, :with_email, shop: shop, session: session) }
      let!(:init_params) { { shop_id: shop.uniqid, v: 3, ssid: session.code } }

      it 'exist' do
        get :init_script, init_params
        expect(JSON.parse(response.body)['profile']).not_to be_nil
      end
    end

    context 'mark sources as clicked' do

      let!(:customer) { create(:customer) }
      let!(:shop) { create(:shop, customer: customer) }
      let!(:init_params) { { shop_id: shop.uniqid } }

      let!(:client) { create(:client, shop: shop) }
      let!(:digest_mailing) { create(:digest_mailing, shop: shop) }
      let!(:batch) { create(:digest_mailing_batch, shop: shop, mailing: digest_mailing) }
      let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'abandoned_cart', liquid_template: '123') }

      let!(:digest_mail) { create(:digest_mail, shop_id: shop.id, mailing: digest_mailing, batch: batch, client: client) }
      let!(:trigger_mail) { create(:trigger_mail, shop_id: shop.id, mailing: trigger_mailing, trigger_data: {a: 1}, client: client) }
      let!(:rtb_impression) { create(:rtb_impression, shop: shop) }

      let!(:web_push_trigger_message) { create(:web_push_trigger_message, shop: shop, client: client, trigger_data: {a: 1}, web_push_trigger_id: 1) }
      let!(:web_push_digest_message) { create(:web_push_digest_message, shop: shop, client: client, web_push_digest_id: 1) }

      it 'clicks digest mail' do
        init_params.merge!(from: 'digest_mail', code: digest_mail.code, map: '2')
        get :init_script, init_params
        digest_mail = DigestMail.first
        expect(DigestMail.first.clicked).to be_truthy
        expect(digest_mail.click_map).to eq([2])
      end

      it 'clicks incorrect digest mail' do
        init_params.merge!(from: 'digest_mail', code: '33313')
        get :init_script, init_params
        expect(DigestMail.first.clicked).to be_falsey
      end

      it 'clicks trigger mail' do
        init_params.merge!(from: 'trigger_mail', code: trigger_mail.code)
        get :init_script, init_params
        expect(TriggerMail.first.clicked).to be_truthy
      end

      it 'clicks rtb impression' do
        init_params.merge!(from: 'r46_returner', code: rtb_impression.code)
        get :init_script, init_params
        expect(RtbImpression.first.clicked).to be_truthy
      end

      it 'clicks web push trigger' do
        init_params.merge!(from: 'web_push_trigger', code: web_push_trigger_message.code)
        get :init_script, init_params
        expect(WebPushTriggerMessage.first.clicked).to be_truthy
      end

      it 'clicks web push digest' do
        init_params.merge!(from: 'web_push_digest', code: web_push_digest_message.code)
        get :init_script, init_params
        expect(WebPushDigestMessage.first.clicked).to be_truthy
      end


    end

  end

end
