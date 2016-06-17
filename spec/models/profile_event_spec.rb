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
    let!(:item_6) { create(:item, shop: shop ) }
    let!(:item_7) { create(:item, shop: shop ) }

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
      end

    end

    context 'tracks fashion' do

      it 'saves fashion gender' do
        ProfileEvent.track_items(user, shop, action, [item_1])
        profile_event = ProfileEvent.first
        expect(profile_event.industry).to eq 'fashion'
        expect(profile_event.property).to eq 'gender'
        expect(profile_event.value).to eq 'm'
      end

      it 'saves fashion size' do
        expect{ ProfileEvent.track_items(user, shop, 'cart', [item_5]) }.to change(ProfileEvent, :count).by 3
        expect( ProfileEvent.where(industry: 'fashion', property: 'size_shoe', value: '38', carts: 1).count ).to eq 1
        expect( ProfileEvent.where(industry: 'fashion', property: 'size_shoe', value: '39', carts: 1).count ).to eq 1
        expect( ProfileEvent.where(industry: 'fashion', property: 'size_shoe', value: '40', carts: 1).count ).to eq 1
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
