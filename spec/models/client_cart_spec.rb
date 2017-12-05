require 'rails_helper'

describe Item do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }

  describe '.track' do

    context 'client cart exists' do

      let!(:client_cart) { create(:client_cart, user: user, shop: shop, items: [1,2,3]) }

      it 'rewrites cart cart' do
        item_1 = OpenStruct.new(id: SecureRandom.random_number(1000))
        item_2 = OpenStruct.new(id: SecureRandom.random_number(1000))
        ClientCart.track(shop, user, [item_1, item_2])
        expect(ClientCart.first.items).to eq [item_1.id, item_2.id]
      end

      it 'deletes empty cart' do
        ClientCart.track(shop, user, [])
        expect(ClientCart.all.count).to eq 0
      end

      it 'updates existing cart' do
        item = OpenStruct.new(id: SecureRandom.random_number(1000))
        ClientCart.track(shop, user, [item])
        expect(ClientCart.first.items).to eq [1,2,3, item.id]
      end

    end

    context 'client cart not exists' do

      it 'creates new cart' do
        expect(ClientCart.all.count).to eq 0
        item = OpenStruct.new(id: SecureRandom.random_number(1000))
        ClientCart.track(shop, user, [item])
        expect(ClientCart.all.count).to eq 1
        expect(ClientCart.first.items).to eq [item.id]
      end

      it 'does nothing' do
        expect(ClientCart.track(shop, user, [])).to eq nil
      end

    end

    context 'update date' do
      let!(:item) { create(:item, shop: shop, uniqid: '4') }
      let!(:item2) { create(:item, shop: shop, uniqid: '5') }
      let!(:client_cart) { create(:client_cart, user: user, shop: shop, items: [item2.id], date: Date.yesterday) }

      it 'updating' do
        expect(client_cart.date).to eq(Date.yesterday)
        ClientCart.track(shop, user, [item])
        expect(client_cart.reload.date).to eq(Date.current)
      end
    end




  end


  describe ".remove_from_cart" do

    let!(:client_cart) { create(:client_cart, user: user, shop: shop, items: [1,2,3]) }

    it 'changes cart' do
      client_cart.remove_from_cart [3,2]
      expect(client_cart.reload.items).to eq [1]
    end

    it 'do nothing on empty ids' do
      client_cart.remove_from_cart []
      expect(client_cart.reload.items).to eq [1,2,3]
    end

    it 'drop cart if cart empty' do
      client_cart.remove_from_cart [3,2,1]
      expect(ClientCart.all.count).to eq 0
    end

  end

end
