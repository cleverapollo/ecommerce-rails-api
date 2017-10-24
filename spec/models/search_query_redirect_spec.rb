require 'rails_helper'

RSpec.describe SearchQueryRedirect, type: :model do
  context 'validations' do
    before :each do
      I18n.locale = 'en'
    end
    let!(:shop) { create(:shop) }

    it 'has valid factory' do
      expect(create(:search_query_redirect, shop_id: shop.id)).to be_valid
    end

    it 'raise duplicate record' do
      create(:search_query_redirect, shop_id: shop.id, query: 'query')
      record = build(:search_query_redirect, shop_id: shop.id, query: 'query')
      expect(record.valid?).to be_falsey
      expect(record.errors.full_messages.join(', ')).to match('Query has already been taken')
    end

    it 'validate shop' do
      record = build(:search_query_redirect, query: 'query')
      expect(record.valid?).to be_falsey
      expect(record.errors.full_messages.join(', ')).to match("Shop can't be blank")
    end

    it 'validate query' do
      record = build(:search_query_redirect, shop_id: shop.id, query: '')
      expect(record.valid?).to be_falsey
      expect(record.errors.full_messages.join(', ')).to match("Query can't be blank")
    end

    it 'validate query downcase' do
      record = create(:search_query_redirect, shop_id: shop.id, query: 'QUERY')
      expect(record.query).to match('query')
    end

    it 'validate redirect link' do
      record = build(:search_query_redirect, shop_id: shop.id, redirect_link: 'query')
      expect(record.valid?).to be_falsey
      expect(record.errors.full_messages.join(', ')).to match('Redirect link is invalid')
    end
  end
end
