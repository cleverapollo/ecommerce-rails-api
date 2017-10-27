require 'rails_helper'

describe Order do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }
  let!(:item) { create(:item, shop: shop) }
  let!(:sample_item) { item.amount = 1; item }

  describe '.persist' do
    before do
      allow(OrderItem).to receive(:persist)
    end

    subject { Sidekiq::Testing.inline! { Order.persist(OpenStruct.new({shop: shop, user: user, order_id: '123', session: session, items: [sample_item], source: nil, order_price: 18000 })) } }

    it 'creates order' do
      expect{ subject }.to change(Order, :count).from(0).to(1)
      expect( Order.first.value ).to eq 18000
    end

    it 'creates order items' do
      subject

      expect(OrderItem.count).to eq(1)
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

  # describe '#recommender' do
  #   let!(:item) { create(:item, shop: shop, amount: 1) }
  #   let!(:action) { create(:action_cl, shop: shop, session: session, event: 'view', object_type: 'Item', object_id: item.uniqid, recommended_by: 'popular') }
  #
  #   subject { Order.persist(OpenStruct.new({shop: shop, user: user, order_id: '123', session: session, items: [item], source: nil, order_price: 18000 })) }
  #
  #   it 'generate with recommended' do
  #     subject
  #     expect(Order.first.recommended?).to be_truthy
  #     expect(OrderItem.first.recommended_by).to eq('popular')
  #   end
  # end
end
