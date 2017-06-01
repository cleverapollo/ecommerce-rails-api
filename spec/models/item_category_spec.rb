require 'rails_helper'

describe ItemCategory do
  let!(:shop) { create(:shop) }

  context 'validates' do
    it 'external_id' do
      params = {shop_id: shop.id, name: 'test'}
      I18n.locale = 'en'
      record = ItemCategory.new(params)
      expect(record.valid?).to be_falsey
      expect(record.errors.full_messages.join(', ')).to match('Category id can\'t be blank')
    end

    it 'insert_or_update' do
      params = {shop_id: shop.id, name: 'test'}
      I18n.locale = 'en'
      expect{ ItemCategory.insert_or_update(params) }.to raise_error("Category id can't be blank, params: #{params.to_json}")
    end
  end
end
