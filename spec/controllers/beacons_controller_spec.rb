require 'rails_helper'

describe BeaconsController do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }
  let!(:params) {
    {
      shop_id: shop.uniqid,
      ssid: session.uniqid,
      type: 'lead',
      uuid: '1234567890',
      major: 'potato_major',
      minor: 'potato_minor',
      platform: 'ios',
      device_type: 'smartphone',
      device_version: 'iphone 6'
    }
  }


  describe 'GET notify' do
    context 'when shop_id is correct' do
      context 'when type = lead' do
        context 'when user had notification 2 weeks ago' do
          before {
            shop.beacon_messages.create(user_id: user.id, session_id: session.id, params: { test: 'test' }, notified: true, created_at: 13.days.ago )
          }

          it 'responds with 204' do
            get :notify, params

            expect(response.code).to eq('204')
          end
        end
        context 'when user didnt had notification for 2 weeks' do
          it 'responds with JSON' do
            get :notify, params

            expect(response.code).to eq('200')
            json = {
              image: 'http://cdn.rees46.com/bk.gif',
              title: 'Обед Кинг Хит – всего за 149 рублей',
              description: "Привет!\nАкция от БургерКинг - покажи на кассе этот экран и получи обед Кинг Хит всего за 149 рублей."
            }
            expect(response.body).to eq(json.to_json)
          end

          it 'creates beacon message with notified: true' do
            get :notify, params

            expect(BeaconMessage.first!.notified).to be_truthy
          end
        end
      end

      context 'when type != lead' do
        before { params[:type] = 'conversion' }

        it 'responds with 204' do
          get :notify, params

          expect(response.code).to eq('204')
        end
      end

      it 'logs all requests' do
        expect {
          get :notify, params
        }.to change(BeaconMessage, :count).from(0).to(1)

        b_m = BeaconMessage.first!

        expect(b_m.shop).to eq(shop)
        expect(b_m.session).to eq(session)
        expect(b_m.user).to eq(user)
        expect(b_m.params[:ssid]).to eq(params[:ssid])
        expect(b_m.params[:type]).to eq(params[:type])
        expect(b_m.params[:uuid]).to eq(params[:uuid])
        expect(b_m.params[:major]).to eq(params[:major])
        expect(b_m.params[:minor]).to eq(params[:minor])
        expect(b_m.params[:platform]).to eq(params[:platform])
        expect(b_m.params[:device_type]).to eq(params[:device_type])
        expect(b_m.params[:device_version]).to eq(params[:device_version])

        expect {
          get :notify, params
        }.to change(BeaconMessage, :count).from(1).to(2)
      end
    end

    context 'when shop_id isnt correct' do
      before { params[:shop_id] = 'incorrect' }

      it 'responds with 400' do
        get :notify, params
        expect(response.code).to eq('400')
      end
    end
  end
end
