require 'rails_helper'

describe YmlWorker do
  let!(:shop) { create(:shop) }

  it 'is a sidekiq worker' do
    expect(subject).to be_kind_of(Sidekiq::Worker)
  end

  describe '#perform' do
    before do
      allow(subject).to receive(:process)
    end

    it 'fetches shop' do
      subject.perform(shop.id)
      expect(subject.shop).to eq(shop)
    end

    it 'calls process' do
      subject.perform(shop.id)
      expect(subject).to have_received(:process).once
    end
  end

  describe '#process' do
    let!(:item1) { create(:item, shop: shop) }
    let!(:item2) { create(:item, shop: shop) }
    let!(:item3) { create(:item, shop: shop, is_available: false) }
    let!(:item4) { create(:item, shop: shop) }

    before do
      yml_items = [{
        'id' => item1.id,
        'price' => '150',
        'available' => 'true'
      },
      {
        'id' => item2.id,
        'price' => item2.price,
        'available' => 'false'
      },
      {
        'id' => item3.id,
        'price' => item3.price,
        'available' => 'true'
      }]
      yml = {
        'yml_catalog' => {
          'shop' => {
            'offers' => {
              'offer' => yml_items
            },
            'categories' => {
              'category' => []
            }
          }
        }
      }
      allow(subject).to receive(:parsed_yml).and_return(yml)
    end

    it 'works with catalog' do
      subject.shop = shop
      subject.process

      expect(item1.reload.price).to eq(150)

      expect(item2.reload.is_available).to be_falsey

      expect(item3.reload.is_available).to be_truthy

      expect(item4.reload.is_available).to be_falsey
    end
  end

  describe '.process_all!' do
    let!(:shop_with_yml) { create(:shop) }
    let!(:shop_without_yml) { create(:shop, :without_yml) }

    it 'starts worker for shops with yml' do
      allow(YmlWorker).to receive(:perform_async)

      YmlWorker.process_all!

      expect(YmlWorker).to have_received(:perform_async).once.with(shop_with_yml.id)
    end
  end
end
