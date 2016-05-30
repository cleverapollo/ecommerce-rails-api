require 'rails_helper'

describe TriggerMailings::SubscriptionForProduct do

  describe '.subscribe_for_price' do

    let!(:user) { create(:user) }
    let!(:shop) { create(:shop) }
    let!(:item) { create(:item, shop: shop, uniqid: '123') }
    subject { TriggerMailings::SubscriptionForProduct.subscribe_for_price shop, user, item }

    context 'it saves subscription' do
      it {
        expect{ subject }.to change(SubscribeForProductPrice, :count).by(1)
      }
    end

    context 'it updates subscription if exists' do
      let!(:subscribe_for_product_price) { create(:subscribe_for_product_price, shop: shop, user: user, item: item, subscribed_at: Time.current) }
      it {
        expect{subject}.not_to change(SubscribeForProductPrice, :count)
      }
    end

    context 'it raises exception if something absent' do
      it {
        expect{ TriggerMailings::SubscriptionForProduct.subscribe_for_price shop, user, nil } .to raise_error(TriggerMailings::SubscriptionForProduct::IncorrectMailingSettingsError)
      }
      it {
        expect{ TriggerMailings::SubscriptionForProduct.subscribe_for_price shop, nil, item }.to raise_error(TriggerMailings::SubscriptionForProduct::IncorrectMailingSettingsError)
      }
      it {
        expect{ TriggerMailings::SubscriptionForProduct.subscribe_for_price nil, user, item }.to raise_error(TriggerMailings::SubscriptionForProduct::IncorrectMailingSettingsError)
      }
    end
  end

  describe '.subscribe_for_available' do

    let!(:user) { create(:user) }
    let!(:shop) { create(:shop) }
    let!(:item) { create(:item, shop: shop, uniqid: '123') }
    subject { TriggerMailings::SubscriptionForProduct.subscribe_for_available shop, user, item }

    context 'it saves subscription' do
      it {
        expect{ subject }.to change(SubscribeForProductAvailable, :count).by(1)
      }
    end

    context 'it updates subscription if exists' do
      let!(:subscribe_for_product_available) { create(:subscribe_for_product_available, shop: shop, user: user, item: item, subscribed_at: Time.current) }
      it {
        expect{subject}.not_to change(SubscribeForProductAvailable, :count)
      }
    end

    context 'it raises exception if something absent' do
      it {
        expect{ TriggerMailings::SubscriptionForProduct.subscribe_for_available shop, user, nil } .to raise_error(TriggerMailings::SubscriptionForProduct::IncorrectMailingSettingsError)
      }
      it {
        expect{ TriggerMailings::SubscriptionForProduct.subscribe_for_available shop, nil, item }.to raise_error(TriggerMailings::SubscriptionForProduct::IncorrectMailingSettingsError)
      }
      it {
        expect{ TriggerMailings::SubscriptionForProduct.subscribe_for_available nil, user, item }.to raise_error(TriggerMailings::SubscriptionForProduct::IncorrectMailingSettingsError)
      }
    end
  end

  describe '.cleanup' do
    context 'cleans old history and saves current history' do
      let!(:user) { create(:user) }
      let!(:shop) { create(:shop) }
      let!(:item) { create(:item, shop: shop, uniqid: '123') }
      let!(:subscribe_for_product_price) { create(:subscribe_for_product_price, shop: shop, user: user, item: item, subscribed_at: 7.month.ago) }
      let!(:subscribe_for_product_available) { create(:subscribe_for_product_available, shop: shop, user: user, item: item, subscribed_at: 7.month.ago) }
      it {
        TriggerMailings::SubscriptionForProduct.cleanup
        expect(SubscribeForProductPrice.count).to eq(0)
        expect(SubscribeForProductAvailable.count).to eq(0)
      }
    end
  end

end
