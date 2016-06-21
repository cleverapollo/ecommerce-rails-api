require 'rails_helper'

describe ProfileEvent do

  describe '.track_items' do

    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer) }
    let!(:user) { create(:user) }

    let!(:item_1) { create(:item, shop: shop, is_fashion: true, fashion_gender: 'm' ) }
    let!(:item_2) { create(:item, shop: shop, is_fashion: true, fashion_gender: 'f' ) }
    let!(:item_3) { create(:item, shop: shop, is_cosmetic: true, cosmetic_gender: 'm' ) }
    let!(:item_4) { create(:item, shop: shop, is_child: true, child_gender: 'm' ) }
    let!(:item_5) { create(:item, shop: shop, is_fashion: true, fashion_wear_type: 'shoe', fashion_sizes: [38, 39, 40] ) }
    let!(:item_6) { create(:item, shop: shop, is_fmcg: true, fmcg_hypoallergenic: true ) }
    let!(:item_7) { create(:item, shop: shop, is_cosmetic: true, cosmetic_hypoallergenic: true ) }
    let!(:item_8) { create(:item, shop: shop, is_cosmetic: true, cosmetic_hair_type: ['long'], cosmetic_hair_condition: ['oily'] ) }
    let!(:item_9) { create(:item, shop: shop, is_cosmetic: true, cosmetic_hair_type: ['long'], cosmetic_hair_condition: ['damage'] ) }


    let!(:item_simple) { create(:item, shop: shop ) }

    let!(:action) { 'view' }

    context 'common calculations' do

      it 'saves 1 event' do
        expect{ ProfileEvent.track_items(user, shop, action, [item_1]) }.to change(ProfileEvent, :count).by 1
        profile_event = ProfileEvent.first
        expect(profile_event.views).to eq 1
      end

      it 'saves 2 events' do
        expect{ ProfileEvent.track_items(user, shop, action, [item_2, item_3]) }.to change(ProfileEvent, :count).by 2
      end

      it 'changes counters' do
        ProfileEvent.track_items(user, shop, action, [item_1])
        ProfileEvent.track_items(user, shop, action, [item_1])
        profile_event = ProfileEvent.first
        expect(profile_event.views).to eq 2
      end

    end

    context 'tracks cosmetic' do

      it 'saves customer gender for cosmetic' do
        ProfileEvent.track_items(user, shop, action, [item_3])
        profile_event = ProfileEvent.first
        expect(profile_event.industry).to eq 'cosmetic'
        expect(profile_event.property).to eq 'gender'
        expect(profile_event.value).to eq 'm'
        expect(user.reload.gender).to eq 'm'
      end

      it 'saves hair type and condition for cosmetic' do
        ProfileEvent.track_items(user, shop, 'view', [item_8, item_9, item_simple])
        ProfileEvent.track_items(user, shop, 'cart', [item_8, item_simple])
        ProfileEvent.track_items(user, shop, 'purchase', [item_9, item_simple])
        expect(ProfileEvent.count).to eq 3
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'hair_condition', value: 'damage').views).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'hair_condition', value: 'damage').purchases).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'hair_condition', value: 'oily').views).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'hair_condition', value: 'oily').carts).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'hair_type', value: 'long').views).to eq 2
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'hair_type', value: 'long').carts).to eq 1
        expect(ProfileEvent.find_by(industry: 'cosmetic', property: 'hair_type', value: 'long').purchases).to eq 1
        expect(user.reload.cosmetic_hair['condition']).to eq('damage')
        expect(user.reload.cosmetic_hair['type']).to eq('long')
      end

      it 'saves allergy for cosmetic' do
        ProfileEvent.track_items(user, shop, 'purchase', [item_7, item_simple])
        ProfileEvent.track_items(user, shop, 'purchase', [item_7, item_simple])
        ProfileEvent.track_items(user, shop, 'purchase', [item_7, item_simple])
        expect(ProfileEvent.count).to eq 1
        profile_event = ProfileEvent.first
        expect(profile_event.industry).to eq 'cosmetic'
        expect(profile_event.property).to eq 'hypoallergenic'
        expect(profile_event.value).to eq '1'
        expect(profile_event.purchases).to eq 3
        expect(user.reload.allergy).to be_truthy
      end

    end

    context 'tracks fmcg' do

      it 'saves allergy for fmcg' do
        ProfileEvent.track_items(user, shop, 'purchase', [item_6, item_simple])
        ProfileEvent.track_items(user, shop, 'purchase', [item_6, item_simple])
        ProfileEvent.track_items(user, shop, 'purchase', [item_6, item_simple])
        expect(ProfileEvent.count).to eq 1
        profile_event = ProfileEvent.first
        expect(profile_event.industry).to eq 'fmcg'
        expect(profile_event.property).to eq 'hypoallergenic'
        expect(profile_event.value).to eq '1'
        expect(profile_event.purchases).to eq 3
        expect(user.reload.allergy).to be_truthy
      end

    end

    context 'tracks fashion' do

      it 'saves fashion gender' do
        ProfileEvent.track_items(user, shop, action, [item_1])
        profile_event = ProfileEvent.first
        expect(profile_event.industry).to eq 'fashion'
        expect(profile_event.property).to eq 'gender'
        expect(profile_event.value).to eq 'm'
        expect(user.reload.gender).to eq 'm'
      end

      it 'saves fashion size' do
        expect{ ProfileEvent.track_items(user, shop, 'cart', [item_5]) }.to change(ProfileEvent, :count).by 3
        expect( ProfileEvent.where(industry: 'fashion', property: 'size_shoe', value: '38', carts: 1).count ).to eq 1
        expect( ProfileEvent.where(industry: 'fashion', property: 'size_shoe', value: '39', carts: 1).count ).to eq 1
        expect( ProfileEvent.where(industry: 'fashion', property: 'size_shoe', value: '40', carts: 1).count ).to eq 1
        expect(user.reload.fashion_sizes['shoe']).to eq [38, 39, 40]
      end

    end

    context 'tracks child' do

      it 'saves fashion gender' do
        ProfileEvent.track_items(user, shop, action, [item_4])
        profile_event = ProfileEvent.first
        expect(profile_event.industry).to eq 'child'
        expect(profile_event.property).to eq 'gender'
        expect(profile_event.value).to eq 'm'
      end

    end

  end



end
