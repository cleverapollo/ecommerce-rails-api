require 'rails_helper'

describe TriggerMailings::SubscriptionForCategory do

  describe '.subscribe' do

    let!(:user) { create(:user) }
    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer) }
    let!(:item_category) { create(:item_category, shop: shop, external_id: '123') }
    subject { TriggerMailings::SubscriptionForCategory.subscribe shop, user, item_category }

    context 'it saves subscription' do
      it {
        expect{ subject }.to change(SubscribeForCategory, :count).by(1)
      }
    end

    context 'it updates subscription if exists' do
      let!(:subscribe_for_category) { create(:subscribe_for_category, shop: shop, user: user, item_category: item_category, subscribed_at: Time.current) }
      it {
        expect{subject}.not_to change(SubscribeForCategory, :count)
      }
    end

    context 'it raises exception if something absent' do
      it {
        expect{ TriggerMailings::SubscriptionForCategory.subscribe shop, user, nil } .to raise_error(TriggerMailings::SubscriptionForCategory::IncorrectMailingSettingsError)
      }
      it {
        expect{ TriggerMailings::SubscriptionForCategory.subscribe shop, nil, item_category }.to raise_error(TriggerMailings::SubscriptionForCategory::IncorrectMailingSettingsError)
      }
      it {
        expect{ TriggerMailings::SubscriptionForCategory.subscribe nil, user, item_category }.to raise_error(TriggerMailings::SubscriptionForCategory::IncorrectMailingSettingsError)
      }
    end
  end

  describe '.cleanup' do
    context 'cleans old history and saves current history' do
      let!(:user) { create(:user) }
      let!(:customer) { create(:customer) }
      let!(:shop) { create(:shop, customer: customer) }
      let!(:item_category) { create(:item_category, shop: shop, external_id: '123') }
      let!(:subscribe_for_category) { create(:subscribe_for_category, shop: shop, user: user, item_category: item_category, subscribed_at: 49.hours.ago) }
      it {
        TriggerMailings::SubscriptionForCategory.cleanup
        expect(SubscribeForCategory.count).to eq(0)
      }
    end
  end

end
