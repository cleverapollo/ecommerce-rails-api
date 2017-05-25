require 'rails_helper'

describe People::Segmentation::DynamicCalculateWorker do
  let!(:shop) { create(:shop) }
  let!(:segment) { create(:segment, shop: shop, segment_type: Segment::TYPE_DYNAMIC) }
  before { %w(hat glove tshirt sock jacket blazer belt shoe underwear trouser shirt).each { |w| WearTypeDictionary.create!(type_name: w, word: Faker::Lorem.word) } }


  # User 1
  let!(:user1) { create(:user,
      gender: 'm',
      fashion_sizes: Hash[WearTypeDictionary.pluck('DISTINCT type_name').map { |t| [t.to_sym, [40, 41, 43, 45]] }],
      children: [{gender: 'm', age_min: 6, age_max: 8}],
      compatibility: { brand: %w(audi bmw), model: %w(a5 a1) }
  ) }
  let!(:client1) { create(:client, user: user1, shop: shop,
      email: 'test@test.com', bought_something: true, location: 'spb', digest_opened: true
  ) }

  # User 2
  let!(:user2) { create(:user,
      fashion_sizes: Hash[WearTypeDictionary.pluck('DISTINCT type_name').map { |t| [t.to_sym, [36, 37]] }],
      children: [{gender: 'm', age_min: 1.5, age_max: 2}],
      compatibility: { brand: %w(bmw), model: %w(x5) }
  ) }
  let!(:client2) { create(:client, user: user2, shop: shop,
      email: 'test2@test.com', bought_something: true, web_push_enabled: true, location: 'spb', digest_opened: true
  ) }

  # User 3
  let!(:user3) { create(:user) }
  let!(:client3) { create(:client, user: user3, shop: shop, email: 'test3@test.com') }

  # Items
  let!(:item1) { create(:item, :recommendable, :widgetable, shop: shop, price: 150, brand: 'brand1', category_ids: ['1']) }
  let!(:item2) { create(:item, :recommendable, :widgetable, shop: shop, price: 50, category_ids: ['3']) }

  # Orders
  let!(:action1) { create(:action, shop: shop, user: user1, item: item1, view_date: 2.hour.ago, purchase_date: 1.hour.ago) }
  let!(:order1) { create(:order, shop: shop, user: user1, value: 150, date: 1.hour.ago) }
  let!(:order_item1) { create(:order_item, shop: shop, order: order1, item: item1, action: action1) }

  let!(:action2) { create(:action, shop: shop, user: user2, item: item2, view_date: 1.month.ago, purchase_date: 1.month.ago) }
  let!(:order2) { create(:order, shop: shop, user: user2, value: 50, date: 1.month.ago) }
  let!(:order_item2) { create(:order_item, shop: shop, order: order2, item: item2, action: action2) }

  # Digest
  let!(:digest_mailing) { create(:digest_mailing, shop: shop, state: 'finished') }
  let!(:digest_mailing_batch) { create(:digest_mailing_batch, mailing: digest_mailing, shop: shop) }
  let!(:digest_mail1) { create(:digest_mail, shop: shop, mailing: digest_mailing, batch: digest_mailing_batch, client: client1, opened: true) }
  let!(:digest_mail2) { create(:digest_mail, shop: shop, mailing: digest_mailing, batch: digest_mailing_batch, client: client2, opened: false) }

  subject { People::Segmentation::DynamicCalculateWorker.new.perform segment.id }

  it 'include all clients' do
    subject
    expect(client1.reload.segment_ids).to include(segment.id)
    expect(client2.reload.segment_ids).to include(segment.id)
    expect(client3.reload.segment_ids).to include(segment.id)
    expect(segment.reload.client_count).to eq(3)
    expect(segment.reload.with_email_count).to eq(3)
    expect(segment.reload.digest_client_count).to eq(3)
    expect(segment.reload.web_push_client_count).to eq(1)
    expect(segment.reload.updating).to be_falsey
  end

  # Demography
  it 'demography filter' do
    segment.update(filters: { demography: {gender: 'm', locations: ['spb']} })
    subject
    expect(client1.reload.segment_ids).to include(segment.id)
    expect(client2.reload.segment_ids).to be_nil
    expect(client3.reload.segment_ids).to be_nil
  end

  # Fashion
  it 'fashion filter' do
    segment.update(filters: { fashion: Hash[WearTypeDictionary.pluck('DISTINCT type_name').map { |t| [t.to_sym, %w(38 40)] }] })
    subject
    expect(client1.reload.segment_ids).to include(segment.id)
    expect(client2.reload.segment_ids).to be_nil
    expect(client3.reload.segment_ids).to be_nil
  end

  # Child
  it 'child filter' do
    segment.update(filters: { child: { available: '1', age: { from: '0', to: '14' } } })
    subject
    expect(client1.reload.segment_ids).to include(segment.id)
    expect(client2.reload.segment_ids).to include(segment.id)
    expect(client3.reload.segment_ids).to be_nil
  end

  it 'child filter with gender' do
    segment.update(filters: { child: { available: '1', age: { from: '6', to: '14' }, gender: 'm' } })
    subject
    expect(client1.reload.segment_ids).to include(segment.id)
    expect(client2.reload.segment_ids).to be_nil
    expect(client3.reload.segment_ids).to be_nil
  end

  # Auto
  it 'auto filter' do
    segment.update(filters: { auto: { brand: ['audi'], model: %w(a5 x5), year: { to: '2005', from: '1997' } } })
    subject
    expect(client1.reload.segment_ids).to include(segment.id)
    expect(client2.reload.segment_ids).to be_nil
    expect(client3.reload.segment_ids).to be_nil
  end

  # Purchase
  context 'purchase history' do
    before { segment.update(filters: { purchase: { bought_something: '1', price: { from: '100', to: '200' } } }) }

    it 'bought_something' do
      subject
      expect(client1.reload.segment_ids).to include(segment.id)
      expect(client2.reload.segment_ids).to be_nil
      expect(client3.reload.segment_ids).to be_nil
    end

    it 'with brand' do
      segment.filters[:purchase][:brand] = %w(brand1 brand2)
      segment.filters[:purchase][:price][:from] = '0'
      segment.save!
      subject
      expect(client1.reload.segment_ids).to include(segment.id)
      expect(client2.reload.segment_ids).to be_nil
      expect(client3.reload.segment_ids).to be_nil
    end

    it 'with purchase range' do
      segment.filters[:purchase][:last] = "#{1.week.ago.to_date} - #{Date.current}"
      segment.filters[:purchase][:price][:from] = '0'
      segment.save!
      subject
      expect(client1.reload.segment_ids).to include(segment.id)
      expect(client2.reload.segment_ids).to be_nil
      expect(client3.reload.segment_ids).to be_nil
    end
  end

  # Marketing
  context 'email marketing' do
    it 'letter_open' do
      segment.update(filters: { marketing: { letter_open: '1' } })
      subject
      expect(client1.reload.segment_ids).to include(segment.id)
      expect(client2.reload.segment_ids).to include(segment.id)
      expect(client3.reload.segment_ids).to be_nil
    end

    it 'letter_open and last digest open' do
      segment.update(filters: { marketing: { letter_open: '1', digest: '1' } })
      subject
      expect(client1.reload.segment_ids).to include(segment.id)
      expect(client2.reload.segment_ids).to be_nil
      expect(client3.reload.segment_ids).to be_nil
    end

    it 'letter_open and last digest not open' do
      segment.update(filters: { marketing: { letter_open: '1', digest: '0' } })
      subject
      expect(client1.reload.segment_ids).to be_nil
      expect(client2.reload.segment_ids).to include(segment.id)
      expect(client3.reload.segment_ids).to be_nil
    end

    # View
    it 'category view period' do
      segment.update(filters: { marketing: { category_viewed: '1', category_view_period: '7' } })
      subject
      expect(client1.reload.segment_ids).to include(segment.id)
      expect(client2.reload.segment_ids).to be_nil
      expect(client3.reload.segment_ids).to be_nil
    end

    it 'category view period with brand' do
      segment.update(filters: { marketing: { category_viewed: '1', category_view_period: '7', category_view_brand: ['brand1'] } })
      subject
      expect(client1.reload.segment_ids).to include(segment.id)
      expect(client2.reload.segment_ids).to be_nil
      expect(client3.reload.segment_ids).to be_nil
    end

    it 'category view period with category' do
      segment.update(filters: { marketing: { category_viewed: '1', category_view_period: '40', category_view: %w(3) } })
      subject
      expect(client1.reload.segment_ids).to be_nil
      expect(client2.reload.segment_ids).to include(segment.id)
      expect(client3.reload.segment_ids).to be_nil
    end

    it 'category view period with brand and category' do
      segment.update(filters: { marketing: { category_viewed: '1', category_view_period: '7', category_view_brand: %w(brand1 brand2), category_view: %w(1 3) } })
      subject
      expect(client1.reload.segment_ids).to include(segment.id)
      expect(client2.reload.segment_ids).to be_nil
      expect(client3.reload.segment_ids).to be_nil
    end

    # Purchase
    it 'category purchase period' do
      segment.update(filters: { marketing: { category_purchased: '1', category_purchase_period: '7' } })
      subject
      expect(client1.reload.segment_ids).to include(segment.id)
      expect(client2.reload.segment_ids).to be_nil
      expect(client3.reload.segment_ids).to be_nil
    end

    it 'category view period with brand' do
      segment.update(filters: { marketing: { category_purchased: '1', category_purchase_period: '7', category_purchase_brand: ['brand1'] } })
      subject
      expect(client1.reload.segment_ids).to include(segment.id)
      expect(client2.reload.segment_ids).to be_nil
      expect(client3.reload.segment_ids).to be_nil
    end

    it 'category view period with category' do
      segment.update(filters: { marketing: { category_purchased: '1', category_purchase_period: '40', category_purchase: %w(3) } })
      subject
      expect(client1.reload.segment_ids).to be_nil
      expect(client2.reload.segment_ids).to include(segment.id)
      expect(client3.reload.segment_ids).to be_nil
    end

    it 'category view period with brand and category' do
      segment.update(filters: { marketing: { category_purchased: '1', category_purchase_period: '7', category_purchase_brand: %w(brand1 brand2), category_purchase: %w(1 3) } })
      subject
      expect(client1.reload.segment_ids).to include(segment.id)
      expect(client2.reload.segment_ids).to be_nil
      expect(client3.reload.segment_ids).to be_nil
    end

    it 'full' do
      segment.update(filters: { marketing: {
          letter_open: '1', digest: '1',
          category_viewed: '1', category_view_period: '7', category_view_brand: %w(brand1 brand2), category_view: %w(1 3),
          category_purchased: '1', category_purchase_period: '7', category_purchase_brand: %w(brand1 brand2), category_purchase: %w(1 3)
      } })
      subject
      expect(client1.reload.segment_ids).to include(segment.id)
      expect(client2.reload.segment_ids).to be_nil
      expect(client3.reload.segment_ids).to be_nil
    end

  end
end