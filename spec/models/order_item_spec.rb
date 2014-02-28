require 'spec_helper'

describe OrderItem do
  describe '.persist' do
    before do
      @user = create(:user)
      @shop = create(:shop)
      @order = create(:order, shop: @shop, user: @user)
      @item = create(:item, shop: @shop)
      @amount = 25
      @action = create(:action, user: @user, shop: @shop, item: @item)
    end

    subject { OrderItem.persist(@order, @item, @amount) }

    it 'persists order_item' do
      expect{ subject }.to change(OrderItem, :count).from(0).to(1)
    end

    it 'attaches order to order_item' do
      expect(subject.order.id).to eq(@order.id)
    end

    it 'attaches action to order_item' do
      expect(subject.action.id).to eq(@action.id)
    end

    it 'saves amount' do
      expect(subject.amount).to eq(@amount)
    end

    it 'saves recommended_by' do
      expect(subject.recommended_by).to eq(@action.recommended_by)
    end
  end
end
