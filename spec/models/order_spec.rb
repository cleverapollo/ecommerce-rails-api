require 'spec_helper'

describe Order do
  before do
    @shop = create(:shop)
    @user = create(:user)
    @sample_item = OpenStruct.new(amount: 1)
  end

  describe '.persist' do
    before do
      allow(OrderItem).to receive(:persist)
    end

    subject { Order.persist(@shop, @user, '123', [@sample_item] ) }

    it 'creates order' do
      expect{ subject }.to change(Order, :count).from(0).to(1)
    end

    it 'creates order items' do
      subject

      expect(OrderItem).to have_received(:persist)
    end
  end

  describe '.duplicate?' do
    before do
      @order = create(:order, shop: @shop, user: @user)
    end

    context 'for orders with given uniqid' do
      it 'returns true if duplicate exists' do
        expect(Order.duplicate?(@shop, @user, @order.uniqid, [])).to eq(true)
      end
    end

    context 'for orders without uniqid' do
      it 'returns true if user made order less than 5 minutes ago' do
        expect(Order.duplicate?(@shop, @user, nil, [])).to eq(true)
      end
    end
  end

  describe '.generate_uniqid' do
    subject { Order.generate_uniqid }

    it 'generates unique id' do
      expect(subject).to be_an_instance_of(String)
    end
  end
end
