require 'rails_helper'

describe Item do
  let!(:shop) { create(:shop) }

  describe ".in_categories" do
    let!(:a)   { create(:item, shop_id: shop.id, category_ids: [1,2]) }
    let!(:b)   { create(:item, shop_id: shop.id, category_ids: [2,3]) }

    it { expect(shop.items.in_categories([1], { any: true }).pluck(:id)).to match_array([a.id]) }
    it { expect(shop.items.in_categories([2], { any: true }).pluck(:id)).to match_array([a.id, b.id]) }
    it { expect(shop.items.in_categories([3], { any: true }).pluck(:id)).to match_array([b.id]) }

    it { expect(shop.items.in_categories([1], { any: false }).pluck(:id)).to match_array([a.id]) }
    it { expect(shop.items.in_categories([2], { any: false }).pluck(:id)).to match_array([a.id, b.id]) }
    it { expect(shop.items.in_categories([3], { any: false }).pluck(:id)).to match_array([b.id]) }
  end

  describe ".in_locations" do
    let!(:a)   { create(:item, shop_id: shop.id, location_ids: [1,2]) }
    let!(:b)   { create(:item, shop_id: shop.id, location_ids: [2,3]) }

    it { expect(shop.items.in_locations([1], { any: true }).pluck(:id)).to match_array([a.id]) }
    it { expect(shop.items.in_locations([2], { any: true }).pluck(:id)).to match_array([a.id, b.id]) }
    it { expect(shop.items.in_locations([3], { any: true }).pluck(:id)).to match_array([b.id]) }

    it { expect(shop.items.in_locations([1], { any: false }).pluck(:id)).to match_array([a.id]) }
    it { expect(shop.items.in_locations([2], { any: false }).pluck(:id)).to match_array([a.id, b.id]) }
    it { expect(shop.items.in_locations([3], { any: false }).pluck(:id)).to match_array([b.id]) }
  end

  describe '#csv_row' do
    let(:id)             { generate(:id) }
    let(:uniqid)         { generate(:uniqid) }
    let(:price)          { 100 }
    let(:is_available)   { rand(3) > 2 }
    let(:name)           { generate(:name) }
    let(:description)    { generate(:description) }
    let(:url)            { generate(:url) }
    let(:image_url)      { generate(:picture_url) }
    let(:widgetable)     { rand(3) > 2 }
    let(:brand)          { generate(:brand) }
    let(:ignored)        { rand(3) > 2 }
    let(:sr)             { rand 10 }
    let(:sales_rate)     { rand 10 }
    let(:type_prefix)    { generate(:type_prefix) }
    let(:vendor_code)    { generate(:vendor_code) }
    let(:model)          { generate(:model) }
    let(:gender)         { generate(:gender) }
    let(:wear_type)      { generate(:wear_type) }
    let(:feature)        { generate(:feature) }
    let(:sizes)          { (1..4).map{ rand 10 } }
    let(:age_min)        { rand(10) }
    let(:age_max)        { 10 + rand(30) }
    let(:hypoallergenic) { rand(3) > 2 }
    let(:part_type)      { [] }
    let(:skin_type)      { [] }
    let(:condition)      { [] }
    let(:volume)         { nil }
    let(:periodic)       { rand(3) > 2 }
    let(:barcode)        { generate(:barcode) }
    let(:categories)     { (1..4).map{ rand 10 } }
    let(:locations)      { (1..4).map{ rand 10 } }
    let(:category_ids)   { (1..4).map{ rand 10 } }
    let(:location_ids)   { (1..4).map{ rand 10 } }
    let(:price_margin)   { rand 10 }
    let(:oldprice)       { rand 1000 }
    let(:discount)       { true }
    let(:is_auto)        { true }
    let(:auto_periodic)  { false }
    let(:is_pets)        { true }
    let(:pets_breed)     { 'dog terrier' }
    let(:pets_type)      { 'dog' }
    let(:pets_age)       { 'old' }
    let(:pets_periodic)  { true }
    let(:pets_size)      { 'large' }
    let(:is_jewelry)     { true }
    let(:jewelry_gender) { 'f' }
    let(:jewelry_color)  { 'yellow' }
    let(:jewelry_metal)  { 'gold' }
    let(:jewelry_gem)    { 'diamond' }
    let(:ring_sizes)     { (1..4).map{ rand 10 } }
    let(:bracelet_sizes) { (1..4).map{ rand 10 } }
    let(:chain_sizes)    { (1..4).map{ rand 10 } }

    subject do
      build(:item, {
        id: id,
        uniqid: uniqid,
        price: price,
        is_available: is_available,
        name: name,
        description: description,
        url: url,
        image_url: image_url,
        widgetable: widgetable,
        brand: brand,
        ignored: ignored,
        locations: locations,
        sr: sr,
        sales_rate: sales_rate,
        type_prefix: type_prefix,
        vendor_code: vendor_code,
        model: model,
        fashion_gender: gender,
        fashion_wear_type: wear_type,
        fashion_feature: feature,
        child_age_min: age_min,
        child_age_max: age_max,
        cosmetic_hypoallergenic: hypoallergenic,
        part_type: part_type,
        skin_type: skin_type,
        condition: condition,
        fmcg_volume: volume,
        cosmetic_periodic: periodic,
        barcode: barcode,
        category_ids: category_ids,
        location_ids: location_ids,
        fashion_sizes: sizes,
        price_margin: price_margin,
        oldprice: oldprice,
        discount: discount,
        is_auto: is_auto,
        auto_periodic: auto_periodic,
        is_pets: is_pets,
        pets_breed: pets_breed,
        pets_type: pets_type,
        pets_age: pets_age,
        pets_periodic: pets_periodic,
        pets_size: pets_size,
        is_jewelry: is_jewelry,
        jewelry_gender: jewelry_gender,
        jewelry_color: jewelry_color,
        jewelry_metal: jewelry_metal,
        jewelry_gem: jewelry_gem,
        ring_sizes: ring_sizes,
        bracelet_sizes: bracelet_sizes,
        chain_sizes: chain_sizes
      })
    end

    it { expect(subject.csv_row[1]).to eq(nil) }
    it { expect(subject.csv_row[2]).to eq(uniqid) }
    it { expect(subject.csv_row[3]).to eq(price) }
    it { expect(subject.csv_row[4]).to eq(is_available) }
    it { expect(subject.csv_row[5]).to eq(name) }
    it { expect(subject.csv_row[6]).to eq(description) }
    it { expect(subject.csv_row[7]).to eq(url) }
    it { expect(subject.csv_row[8]).to eq(image_url) }
    it { expect(subject.csv_row[9]).to eq(widgetable) }
    it { expect(subject.csv_row[10]).to eq(brand) }
    it { expect(subject.csv_row[11]).to eq(ignored) }
    it { expect(subject.csv_row[12]).to eq("[#{locations.join(',')}]") }
    it { expect(subject.csv_row[13]).to eq(sr) }
    it { expect(subject.csv_row[14]).to eq(sales_rate) }
    it { expect(subject.csv_row[15]).to eq(type_prefix) }
    it { expect(subject.csv_row[16]).to eq(vendor_code) }
    it { expect(subject.csv_row[17]).to eq(model) }
    it { expect(subject.csv_row[18]).to eq(gender) }
    it { expect(subject.csv_row[19]).to eq(wear_type) }
    it { expect(subject.csv_row[20]).to eq(feature) }
    it { expect(subject.csv_row[21]).to eq(age_min) }
    it { expect(subject.csv_row[22]).to eq(age_max) }
    it { expect(subject.csv_row[35]).to eq(hypoallergenic) }
    it { expect(subject.csv_row[24]).to eq("{#{part_type.join(',')}}") }
    it { expect(subject.csv_row[25]).to eq("{#{skin_type.join(',')}}") }
    it { expect(subject.csv_row[26]).to eq("{#{condition.join(',')}}") }
    it { expect(subject.csv_row[27]).to eq(volume) }
    it { expect(subject.csv_row[42]).to eq(periodic) }
    it { expect(subject.csv_row[29]).to eq(barcode) }
    it { expect(subject.csv_row[30]).to eq("{#{category_ids.join(',')}}") }
    it { expect(subject.csv_row[31]).to eq("{#{location_ids.join(',')}}") }
    it { expect(subject.csv_row[32]).to eq(price_margin) }
    it { expect(subject.csv_row[33]).to eq("{#{sizes.join(',')}}") }
    it { expect(subject.csv_row[49]).to eq(oldprice) }
    it { expect(subject.csv_row[51]).to eq(true) }
    it { expect(subject.csv_row[52]).to eq(is_auto) }
    it { expect(subject.csv_row[54]).to eq(false) }
    it { expect(subject.csv_row[56]).to eq(is_pets) }
    it { expect(subject.csv_row[57]).to eq(pets_breed) }
    it { expect(subject.csv_row[58]).to eq(pets_type) }
    it { expect(subject.csv_row[59]).to eq(pets_age) }
    it { expect(subject.csv_row[60]).to eq(pets_periodic) }
    it { expect(subject.csv_row[61]).to eq(pets_size) }
    it { expect(subject.csv_row[63]).to eq(is_jewelry) }
    it { expect(subject.csv_row[64]).to eq(jewelry_gender) }
    it { expect(subject.csv_row[65]).to eq(jewelry_color) }
    it { expect(subject.csv_row[66]).to eq(jewelry_metal) }
    it { expect(subject.csv_row[67]).to eq(jewelry_gem) }
    it { expect(subject.csv_row[68]).to eq("[#{ring_sizes.join(',')}]") }
    it { expect(subject.csv_row[69]).to eq("[#{bracelet_sizes.join(',')}]") }
    it { expect(subject.csv_row[70]).to eq("[#{chain_sizes.join(',')}]") }
  end

  describe '.fetch' do
    subject { Item.fetch(shop.id, @item_data) }

    context 'when item exsists' do
      before { @item_data = create(:item, shop: shop) }

      it 'fetches that item' do
        expect(subject).to eq(@item_data)
      end
    end

    context 'when item not exsists' do
      before { @item_data = build(:item, shop: shop) }

      it 'creates an item' do
        expect{subject}.to change(Item, :count).from(0).to(1)
      end

      it 'stores item uniqid' do
        expect(subject.uniqid).to eq(@item_data.uniqid)
      end
    end
  end

  describe '#disable!' do
    let(:shop) { create(:shop) }
    let!(:item) { create(:item, shop: shop, widgetable: true) }

    it 'disables the item' do
      item.disable!

      expect(item.is_available).to be_falsey
      expect(item.widgetable).to be_falsey
    end
  end
end
