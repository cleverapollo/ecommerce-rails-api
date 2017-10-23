require 'rails_helper'

describe NoResultQuery do
  let!(:shop) { create(:shop) }

  context 'validates' do
    it 'shop_id' do
      params = { query: 'coa', synonym: 'coat' }
      record = NoResultQuery.new(params)
      expect(record.valid?).to be_falsey
      expect(record.errors.full_messages.join(', ')).to match('Shop can\'t be blank')
    end

    it 'query' do
      params = {shop_id: shop.id, synonym: 'test'}
      record = NoResultQuery.new(params)
      expect(record.valid?).to be_falsey
      expect(record.errors.full_messages.join(', ')).to match('Query can\'t be blank')
    end
  
    it 'uniqueness for query' do
      params = {shop_id: shop.id, query: 'test'}
      NoResultQuery.create(params)
      record2 = NoResultQuery.new(params)
      expect(record2.valid?).to be_falsey
      expect(record2.errors.full_messages.join(', ')).to match('Query has already been taken')
    end
  end
end
