require 'rails_helper'

describe ItemsImportWorker do
  let!(:shop) { create(:shop) }
  let!(:items) {
    [
        {
            id: 1,
            name: 'Shtaniy',
            price: 1.0,
            currency: 'USD',
            url: 'http://google.com',
            picture: 'http://google.com/1.png',
            available: true,
            categories: [1],
            locations: [{location: 'spb', price: 2.0}],
            brand: 'typo',
            barcode: 'xxx',
            price_margin: 1,
            tags: [],
            is_child: true,
            is_fashion: true,
            fashion: {
                gender: 'm',
                sizes: [37],
                type: 'shoe'
            }
        },
    ]
  }
  subject { ItemsImportWorker.new.perform(shop.id, items, :put) }

  it 'works' do
    subject

    expect(Item.first.uniqid).to eq(items.first[:id].to_s)
    expect(Item.first.name).to eq(items.first[:name].to_s)
    expect(Item.first.price).to eq(items.first[:price])
    expect(Item.first.url).to eq(items.first[:url])
    expect(Item.first.image_url).to eq(items.first[:picture])
    expect(Item.first.is_available).to eq(items.first[:available])
    expect(Item.first.category_ids).to eq(items.first[:categories].map{|c| c.to_s})

    expect(Item.first.locations).to eq(items.first[:locations].map{|l| l.stringify_keys})
    expect(Item.first.location_ids).to eq(items.first[:locations].map{|l| l[:location]})

    expect(Item.first.brand).to eq(items.first[:brand])
    expect(Item.first.barcode).to eq(items.first[:barcode])
    expect(Item.first.price_margin).to eq(items.first[:price_margin])
    expect(Item.first.is_child).to eq(items.first[:is_child])

    expect(Item.first.is_fashion).to eq(items.first[:is_fashion])
    expect(Item.first.fashion_sizes).to eq(items.first[:fashion][:sizes].map{|s| s.to_s})
    expect(Item.first.fashion_gender).to eq(items.first[:fashion][:gender])
    expect(Item.first.fashion_wear_type).to eq(items.first[:fashion][:type])

    expect(CatalogImportLog.count).to eq(1)
  end

  it 'delete works' do
    subject
    ItemsImportWorker.new.perform(shop.id, [items.first[:id]], :delete)

    expect(Item.first.is_available).to be_falsey
  end

  context 'disable another items' do
    let!(:item) { create(:item, shop: shop, uniqid: 2, is_available: true) }
    it 'works' do
      ItemsImportWorker.new.perform(shop.id, items)

      expect(Item.count).to eq(2)
      expect(Item.find_by(shop: shop, uniqid: 1).is_available).to eq(items.first[:available])
      expect(Item.find_by(shop: shop, uniqid: 2).is_available).to eq(false)
    end

    it 'works add' do
      ItemsImportWorker.new.perform(shop.id, items, :put)

      expect(Item.count).to eq(2)
      expect(Item.find_by(shop: shop, uniqid: 1).is_available).to eq(items.first[:available])
      expect(Item.find_by(shop: shop, uniqid: 2).is_available).to eq(true)
    end
  end
end
