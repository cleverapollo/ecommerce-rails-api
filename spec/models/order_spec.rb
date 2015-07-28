require 'rails_helper'

describe Order do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:sample_item) { OpenStruct.new(amount: 1) }

  describe '.persist' do
    before do
      allow(OrderItem).to receive(:persist)
    end

    subject { Order.persist(shop, user, '123', [sample_item] ) }

    it 'creates order' do
      expect{ subject }.to change(Order, :count).from(0).to(1)
    end

    it 'creates order items' do
      subject

      expect(OrderItem).to have_received(:persist)
    end
  end

  describe '.duplicate?' do
    let!(:order) { create(:order, shop: shop, user: user) }

    context 'for orders with given uniqid' do
      it 'returns true if duplicate exists' do
        expect(Order.duplicate?(shop, user, order.uniqid, [])).to eq(true)
      end
    end

    context 'for orders without uniqid' do
      it 'returns true if user made order less than 5 minutes ago' do
        expect(Order.duplicate?(shop, user, nil, [])).to eq(true)
      end
    end
  end

  describe '.generate_uniqid' do
    subject { Order.generate_uniqid(shop.id) }

    it 'generates unique id' do
      expect(subject).to be_an_instance_of(String)
    end
  end

  describe '#expire_carts' do
    let!(:item) { create(:item, shop: shop) }
    let!(:action) { create(:action, shop: shop, user: user, item: item, rating: Actions::Cart::RATING) }
    let!(:order) { create(:order, shop: shop, user: user) }
    subject { order.expire_carts }

    it 'removes all user carts in current shop' do
      subject
      expect(action.reload.rating).to eq(Actions::RemoveFromCart::RATING)
    end
  end
end
