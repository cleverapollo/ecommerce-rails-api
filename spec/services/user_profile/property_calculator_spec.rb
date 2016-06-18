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
end
