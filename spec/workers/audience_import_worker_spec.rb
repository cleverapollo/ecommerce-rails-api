require 'rails_helper'

describe AudienceImportWorker do
  pending 'Broken'
  # describe '#perform' do
  #   let!(:shop) { create(:shop) }
  #   let!(:params) do
  #     {
  #       'shop_id' => shop.uniqid,
  #       'shop_secret' => shop.secret,
  #       'audiences' => []
  #     }
  #   end

  #   it 'fetches shop' do
  #     subject.perform(params)

  #     expect(subject.shop).to eq(shop)
  #   end

  #   context 'works with audience' do
  #     context 'when audience does not exists' do
  #       let(:audience_raw) { { 'id' => '123', 'email' => 'test@example.com', 'name' => 'Test' } }
  #       before { params['audiences'] << audience_raw }

  #       it 'creates new audience' do
  #         expect{ subject.perform(params) }.to change(shop.audiences, :count).from(0).to(1)
  #       end

  #       it 'saves new audience email' do
  #         subject.perform(params)
  #         expect(Audience.first.email).to eq(audience_raw['email'])
  #       end

  #       it 'saves new audience external_id' do
  #         subject.perform(params)
  #         expect(Audience.first.external_id).to eq(audience_raw['id'])
  #       end

  #       it 'saves new audience custom_attributes' do
  #         subject.perform(params)
  #         expect(Audience.first.custom_attributes['name']).to eq(audience_raw['name'])
  #       end
  #     end

  #     context 'when audience exists by external_id' do
  #       let(:audience_raw) { { 'id' => '123', 'email' => 'test@example.com', 'name' => 'Test' } }
  #       let!(:audience) { create(:audience, shop: shop, external_id: audience_raw['id']) }
  #       before { params['audiences'] << audience_raw }

  #       it 'updates email' do
  #         subject.perform(params)
  #         expect(audience.reload.email).to eq(audience_raw['email'])
  #       end

  #       it 'updates attributes' do
  #         subject.perform(params)
  #         expect(audience.reload.custom_attributes['name']).to eq(audience_raw['name'])
  #       end
  #     end

  #     context 'when audience exists by email' do
  #       let(:audience_raw) { { 'id' => '123', 'email' => 'test@example.com', 'name' => 'Test' } }
  #       let!(:audience) { create(:audience, shop: shop, email: audience_raw['email']) }
  #       before { params['audiences'] << audience_raw }

  #       it 'changes nothing' do
  #         subject.perform(params)

  #         expect(Audience.count).to eq(1)
  #         expect(audience.reload.external_id).to_not eq(audience_raw['id'])
  #       end
  #     end

  #     context 'validations' do
  #       context 'when email is blank' do
  #         let(:audience_raw) { { 'id' => '123', 'email' => '', 'name' => 'Test' } }
  #         before { params['audiences'] << audience_raw }

  #         it 'does nothing' do
  #           expect{ subject.perform(params) }.to_not change(Audience, :count)
  #         end
  #       end

  #       context 'when id is blank' do
  #         let(:audience_raw) { { 'id' => '', 'email' => 'test@example.com', 'name' => 'Test' } }
  #         before { params['audiences'] << audience_raw }

  #         it 'does nothing' do
  #           expect{ subject.perform(params) }.to_not change(Audience, :count)
  #         end
  #       end

  #       context 'when email is invalid' do
  #         let(:audience_raw) { { 'id' => '123', 'email' => 'invalid', 'name' => 'Test' } }
  #         before { params['audiences'] << audience_raw }

  #         it 'does nothing' do
  #           expect{ subject.perform(params) }.to_not change(Audience, :count)
  #         end
  #       end
  #     end
  #   end
  # end
end
