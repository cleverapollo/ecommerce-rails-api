require 'rails_helper'

describe OrderItem do
  describe '.persist' do
    before do
      @user = create(:user)
      @session = create(:session, user: @user)
      @shop = create(:shop)
      @order = create(:order, shop: @shop, user: @user)
      @item = create(:item, shop: @shop)
      @amount = 25
      @action = create(:action, user: @user, shop: @shop, item: @item)
      @params = OpenStruct.new({
          session: @session,
          user: @user,
          shop: @shop,
          current_session_code: 'test'
      })
    end

    subject { OrderItem.persist(@order, @item, @amount, @params) }

    it 'persists order_item' do
      expect{ subject }.to change(OrderItem, :count).from(0).to(1)
    end

    it 'clickhouse save' do
      allow(ClickhouseQueue).to receive(:push).with('order_items', anything, anything)
      subject
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
