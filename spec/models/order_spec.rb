require 'rails_helper'

describe Order do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }
  let!(:client) { create(:client, shop: shop, session: session) }
  let!(:item) { create(:item, shop: shop) }
  let!(:sample_item) { item.amount = 1; item }

  describe '.persist' do

    subject { Sidekiq::Testing.inline! { Order.persist(OpenStruct.new({shop: shop, user: user, order_id: '123', session: session, client: client, items: [sample_item], source: nil, order_price: 18000 })) } }

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
        expect(Order.duplicate?(shop, user, order.uniqid, client)).to eq(true)
      end
    end

    context 'for orders without uniqid' do
      it 'returns true if user made order less than 5 minutes ago' do
        expect(Order.duplicate?(shop, user, nil, client)).to eq(true)
      end
    end
  end

  describe '.generate_uniqid' do
    subject { Order.generate_uniqid(shop.id) }

    it 'generates unique id' do
      expect(subject).to be_an_instance_of(String)
    end
  end
end
