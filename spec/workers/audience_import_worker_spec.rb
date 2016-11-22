require 'rails_helper'

describe AudienceImportWorker do
  describe '#perform' do
    let!(:shop) { create(:shop) }
    let!(:params) do
      {
        'shop_id' => shop.uniqid,
        'shop_secret' => shop.secret,
        'audience' => []
      }
    end

    it 'fetches shop' do
      subject.perform(params)

      expect(subject.shop).to eq(shop)
    end

    context 'works with audience' do
      context 'when client does not exists' do
        let(:audience_raw) { { 'id' => '123', 'email' => 'test@rees46demo.com' } }
        before { params['audience'] << audience_raw }

        it 'creates new client' do
          expect{ subject.perform(params) }.to change(shop.clients, :count).from(0).to(1)
        end

        it 'saves new client email' do
          subject.perform(params)
          expect(Client.first.email).to eq(audience_raw['email'])
        end

        it 'saves new client external_id' do
          subject.perform(params)
          expect(Client.first.external_id).to eq(audience_raw['id'])
        end
      end

      context 'when client exists by external_id' do
        let(:audience_raw) { { 'id' => '123', 'email' => 'test@rees46demo.com', 'name' => 'Test' } }
        let!(:user) { create(:user) }
        let!(:client) { create(:client, shop: shop, external_id: audience_raw['id'], user: user) }
        before { params['audience'] << audience_raw }

        it 'create new client email' do
          subject.perform(params)
          expect(Client.count).to eq(2)
        end
      end

      context 'validations' do
        context 'when email is blank' do
          let(:audience_raw) { { 'id' => '123', 'email' => '', 'name' => 'Test' } }
          before { params['audience'] << audience_raw }

          it 'does nothing' do
            expect{ subject.perform(params) }.to_not change(Client, :count)
          end
        end

        context 'when id is blank' do
          let(:audience_raw) { { 'id' => '', 'email' => 'test@rees46demo.com', 'name' => 'Test' } }
          before { params['audience'] << audience_raw }

          it 'save new user if user not exists' do
            expect{ subject.perform(params) }.to change(Client, :count)
          end
        end

        context 'when email is invalid' do
          let(:audience_raw) { { 'id' => '123', 'email' => 'invalid', 'name' => 'Test' } }
          before { params['audience'] << audience_raw }

          it 'does nothing' do
            expect{ subject.perform(params) }.to_not change(Client, :count)
          end
        end

        context 'when two clients with same email with different external_id' do
          let(:audience_raw) {{ 'id' => '123', 'email' => 'test@rees46demo.com', 'name' => 'Test' }}
          let(:audience_raw_next) {{ 'id' => '321', 'email' => 'test@rees46demo.com', 'name' => 'Test' }}
          before :each do
            params['audience'] << audience_raw
            params['audience'] << audience_raw_next
          end
          it 'create one user' do
            subject.perform(params)
            expect(Client.count).to eq(1)
          end
        end

        context 'can not create two users with same email with different external_id' do
          let(:audience_raw) {{ 'id' => '123', 'email' => 'test@rees46demo.com', 'name' => 'Test' }}
          let(:audience_raw_next) {{ 'id' => '123', 'email' => 'test2@rees46demo.com', 'name' => 'Test' }}
          before :each do
            params['audience'] << audience_raw
            params['audience'] << audience_raw_next
          end
          it 'create two users' do
            subject.perform(params)
            expect(Client.count).to eq(2)
          end
        end
      end
    end
  end
end
