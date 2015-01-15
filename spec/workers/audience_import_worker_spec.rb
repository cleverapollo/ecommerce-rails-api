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
      context 'when shops_user does not exists' do
        let(:audience_raw) { { 'id' => '123', 'email' => 'test@example.com' } }
        before { params['audience'] << audience_raw }

        it 'creates new shops_user' do
          expect{ subject.perform(params) }.to change(shop.shops_users, :count).from(0).to(1)
        end

        it 'saves new shops_user email' do
          subject.perform(params)
          expect(ShopsUser.first.email).to eq(audience_raw['email'])
        end

        it 'saves new shops_user external_id' do
          subject.perform(params)
          expect(ShopsUser.first.external_id).to eq(audience_raw['id'])
        end
      end

      context 'when shops_user exists by external_id' do
        let(:audience_raw) { { 'id' => '123', 'email' => 'test@example.com', 'name' => 'Test' } }
        let!(:user) { create(:user) }
        let!(:shops_user) { create(:shops_user, shop: shop, external_id: audience_raw['id'], user: user) }
        before { params['audience'] << audience_raw }

        it 'updates email' do
          subject.perform(params)
          expect(shops_user.reload.email).to eq(audience_raw['email'])
        end
      end

      context 'validations' do
        context 'when email is blank' do
          let(:audience_raw) { { 'id' => '123', 'email' => '', 'name' => 'Test' } }
          before { params['audience'] << audience_raw }

          it 'does nothing' do
            expect{ subject.perform(params) }.to_not change(ShopsUser, :count)
          end
        end

        context 'when id is blank' do
          let(:audience_raw) { { 'id' => '', 'email' => 'test@example.com', 'name' => 'Test' } }
          before { params['audience'] << audience_raw }

          it 'does nothing' do
            expect{ subject.perform(params) }.to_not change(ShopsUser, :count)
          end
        end

        context 'when email is invalid' do
          let(:audience_raw) { { 'id' => '123', 'email' => 'invalid', 'name' => 'Test' } }
          before { params['audience'] << audience_raw }

          it 'does nothing' do
            expect{ subject.perform(params) }.to_not change(ShopsUser, :count)
          end
        end
      end
    end
  end
end
