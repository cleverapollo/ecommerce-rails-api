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

        it 'updates email' do
          subject.perform(params)
          expect(client.reload.email).to eq(audience_raw['email'])
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

          it 'does nothing' do
            expect{ subject.perform(params) }.to_not change(Client, :count)
          end
        end

        context 'when email is invalid' do
          let(:audience_raw) { { 'id' => '123', 'email' => 'invalid', 'name' => 'Test' } }
          before { params['audience'] << audience_raw }

          it 'does nothing' do
            expect{ subject.perform(params) }.to_not change(Client, :count)
          end
        end
      end
    end
  end
end
