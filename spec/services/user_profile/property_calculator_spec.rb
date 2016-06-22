require 'rails_helper'

describe UserProfile::PropertyCalculator do

  describe '.calculate_gender' do
    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }
    let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'gender', value: 'm', views: 1, carts: 2, purchases: 3) }

    subject { UserProfile::PropertyCalculator.new.calculate_gender(user) }

    context 'gender undefined' do
      let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'gender', value: 'm', views: 1, carts: 2, purchases: 3) }
      let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'gender', value: 'f', views: 1, carts: 2, purchases: 3) }

      it 'returns undefined gender when both genders history is equal' do
        expect(subject).to be_nil
      end
    end


    context 'calculates as usual' do
      let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'gender', value: 'm', views: 1, carts: 2, purchases: 3) }
      let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'gender', value: 'f', views: 2, carts: 2, purchases: 3) }

      it 'returns female' do
        expect(subject).to eq 'f'
      end
    end

    context 'purchases more important' do
      let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'gender', value: 'f', carts: 2) }
      let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'gender', value: 'm', purchases: 1) }

      it 'returns male because purchase more important' do
        expect(subject).to eq 'm'
      end
    end
  end

  describe '.calculate_fashion_sizes' do

    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }


    subject { UserProfile::PropertyCalculator.new.calculate_fashion_sizes(user) }

    context 'no events' do

      it 'returns nil' do
        expect(subject).to eq nil
      end

    end

    context 'with valid events' do

      let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'size_shoe', value: '38', purchases: 3) }
      let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'size_shoe', value: '39', views: 1, carts: 2, purchases: 2) }
      let!(:profile_event_3) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'size_shoe', value: '40', views: 1, carts: 1) }
      let!(:profile_event_4) { create(:profile_event, shop: shop, user: user, industry: 'fashion', property: 'size_coat', value: '33', views: 1) }

      it 'calculates two sizes' do
        expect(subject['shoe']).to eq [38, 39]
        expect(subject['coat']).to eq [33]
      end

    end


  end


  describe 'calculate hair' do

    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }

    let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'hair_type', value: 'long', carts: 2) }
    let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'hair_type', value: 'short', purchases: 2) }
    let!(:profile_event_3) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'hair_condition', value: 'oily', purchases: 1, views: 2) }
    let!(:profile_event_4) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'hair_condition', value: 'damage', purchases: 1, carts: 1, views: 1) }

    subject { UserProfile::PropertyCalculator.new.calculate_hair(user) }

    it 'calculates hair' do
      expect(subject[:type]).to eq 'short'
      expect(subject[:condition]).to eq 'damage'
    end

  end

  describe 'calculate skin' do

    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }

    let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'skin_type_body', value: 'dry', purchases: 2 ) }
    let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'skin_type_body', value: 'normal', views: 1, carts: 2 ) }
    let!(:profile_event_3) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'skin_type_hand', value: 'normal', carts: 1 ) }
    let!(:profile_event_4) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'skin_condition_hand', value: 'damage', carts: 2 ) }
    let!(:profile_event_5) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'skin_condition_body', value: 'soft', carts: 2 ) }

    subject { UserProfile::PropertyCalculator.new.calculate_skin(user) }

    it 'calculates skin' do
      expect(subject['hand']['type']).to eq ['normal']
      expect(subject['hand']['condition']).to eq ['damage']
      expect(subject['body']['type']).to eq ['dry', 'normal']
      expect(subject['body']['condition']).to eq ['soft']
    end

  end


  describe 'calculate allergy' do

    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }

    let!(:profile_event_1) { create(:profile_event, shop: shop, user: user, industry: 'fmcg', property: 'hypoallergenic', value: '1', carts: 2) }
    let!(:profile_event_2) { create(:profile_event, shop: shop, user: user, industry: 'cosmetic', property: 'hypoallergenic', value: '1', purchases: 1, carts: 1) }

    subject { UserProfile::PropertyCalculator.new.calculate_allergy(user) }

    it 'calculates allergy' do
      expect(subject).to be_truthy
    end

  end


end
