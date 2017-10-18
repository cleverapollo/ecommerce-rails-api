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
            },
            cosmetic: {
                gender: 'f',
                hypoallergenic: true,
                skin: {
                    part: ['face'],
                    type: ['dry'],
                    condition: ['dehydrated'],
                },
                hair: {
                    type: ['dry'],
                    condition: ['colored'],
                },
                periodic: true,
                nail: {
                    type: 'polish',
                    polish_color: 'red',
                },
                perfume: {
                    aroma: 'fruity',
                    family: 'woody',
                },
                professional: true
            },
        },
    ]
  }
  subject { ItemsImportWorker.new.perform(shop.id, items, 'put') }

  it 'valid url' do
    items[0][:url] = 'ttp://google.com'
    allow(ErrorsMailer).to receive(:products_import_error).with(shop, 'Url not valid 1 ttp://google.com').and_call_original
    subject
  end

  it 'works' do
    subject

    item = Item.first
    expect(item.uniqid).to eq(items.first[:id].to_s)
    expect(item.name).to eq(items.first[:name].to_s)
    expect(item.price).to eq(items.first[:price])
    expect(item.url).to eq(items.first[:url])
    expect(item.image_url).to eq(items.first[:picture])
    expect(item.is_available).to eq(items.first[:available])
    expect(item.category_ids).to eq(items.first[:categories].map{|c| c.to_s})

    expect(item.locations).to eq(items.first[:locations].map{|l| l.stringify_keys})
    expect(item.location_ids).to eq(items.first[:locations].map{|l| l[:location]})

    expect(item.brand).to eq(items.first[:brand])
    expect(item.barcode).to eq(items.first[:barcode])
    expect(item.price_margin).to eq(items.first[:price_margin])
    expect(item.is_child).to eq(items.first[:is_child])

    expect(item.is_fashion).to eq(items.first[:is_fashion])
    expect(item.fashion_sizes).to eq(items.first[:fashion][:sizes].map{|s| s.to_s})
    expect(item.fashion_gender).to eq(items.first[:fashion][:gender])
    expect(item.fashion_wear_type).to eq(items.first[:fashion][:type])

    expect(item.cosmetic_gender).to eq('f')
    expect(item.cosmetic_hypoallergenic).to eq(true)
    expect(item.cosmetic_skin_part).to eq(['face'])
    expect(item.cosmetic_skin_type).to eq(['dry'])
    expect(item.cosmetic_skin_condition).to eq(['dehydrated'])
    expect(item.cosmetic_hair_type).to eq(['dry'])
    expect(item.cosmetic_hair_condition).to eq(['colored'])
    expect(item.cosmetic_periodic).to eq(true)
    expect(item.cosmetic_nail).to eq(true)
    expect(item.cosmetic_nail_type).to eq('polish')
    expect(item.cosmetic_nail_color).to eq('red')
    expect(item.cosmetic_perfume_aroma).to eq('fruity')
    expect(item.cosmetic_perfume_family).to eq('woody')
    expect(item.cosmetic_professional).to eq(true)

    expect(CatalogImportLog.count).to eq(1)
  end

  it 'works with empty industries' do
    ItemsImportWorker.new.perform(shop.id, [{
        id: 1,
        name: 'Shtaniy',
        price: 1.0,
        url: 'http://google.com',
        picture: 'http://google.com/1.png',
        categories: [],
        available: true,
    }], 'put')

    item = Item.first
    expect(item.uniqid).to eq('1')
    expect(item.name).to eq('Shtaniy')
    expect(item.price).to eq(1.0)
    expect(item.url).to eq('http://google.com')
    expect(item.image_url).to eq('http://google.com/1.png')
    expect(item.is_available).to eq(true)

    expect(item.is_fashion).to be_nil
    expect(item.fashion_sizes).to be_nil
    expect(item.fashion_gender).to be_nil
    expect(item.fashion_wear_type).to be_nil

    expect(item.is_cosmetic).to be_nil
    expect(item.cosmetic_gender).to be_nil
    expect(item.cosmetic_hypoallergenic).to be_nil
    expect(item.cosmetic_skin_part).to be_nil
    expect(item.cosmetic_skin_type).to be_nil
    expect(item.cosmetic_skin_condition).to be_nil
    expect(item.cosmetic_hair_type).to be_nil
    expect(item.cosmetic_hair_condition).to be_nil
    expect(item.cosmetic_periodic).to be_nil
    expect(item.cosmetic_nail).to be_nil
    expect(item.cosmetic_nail_type).to be_nil
    expect(item.cosmetic_nail_color).to be_nil
    expect(item.cosmetic_perfume_aroma).to be_nil
    expect(item.cosmetic_professional).to be_nil

    expect(CatalogImportLog.count).to eq(1)
  end

  it 'delete works' do
    subject
    ItemsImportWorker.new.perform(shop.id, [items.first[:id]], 'delete')

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
      ItemsImportWorker.new.perform(shop.id, items, 'put')

      expect(Item.count).to eq(2)
      expect(Item.find_by(shop: shop, uniqid: 1).is_available).to eq(items.first[:available])
      expect(Item.find_by(shop: shop, uniqid: 2).is_available).to eq(true)
    end

    it 'patch is_available' do
      ItemsImportWorker.new.perform(shop.id, items, 'put')
      ItemsImportWorker.new.perform(shop.id, ['1'], 'patch')

      expect(Item.count).to eq(2)
      expect(Item.find_by(shop: shop, uniqid: 1).is_available).to eq(true)
      expect(Item.find_by(shop: shop, uniqid: 2).is_available).to eq(false)
    end
  end
end
