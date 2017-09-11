require 'rails_helper'

RSpec.describe Recommender, :type => :model do
  let!(:shop) { create(:shop) }
  let!(:item) { create(:item, shop: shop) }
  let!(:item2) { create(:item, shop: shop) }
  let!(:user) { create(:user) }
  let!(:recommender_block) { create(:recommender_block, shop: shop, rules: []) }

  # Часть параметров указывается абстрактно, т.к. создаем mock объекты для рекомендеров.
  let(:params) { OpenStruct.new(shop: shop, user: user, item: item, categories: [1]) }

  # Создаем mock объекты, т.к. в этом тесте нам не важно как работает сам рекомендер
  before { allow_any_instance_of(RecAlgo::Impl::Popular).to receive(:recommendations).and_return([item.uniqid]) }
  before { allow_any_instance_of(RecAlgo::Impl::PopularInCategory).to receive(:recommendations).and_return([item2.uniqid]) }

  subject { recommender_block.recommends(params) }

  context '.rules' do

    # Условия в выборке пути
    context '.condition' do
      before do
        recommender_block.update(rules: [
          {
              type: 'condition',
              condition: 'cart',
              yes: [
                  {
                      type: 'recommender',
                      recommender: 'popular'
                  }
              ],
              no: [
                  {
                      type: 'recommender',
                      recommender: 'popular_in_category'
                  }
              ]
          },
        ])
      end

      it 'do it true' do
        params.cart_item_ids = [item.id]
        expect(subject).to include(item.uniqid)
      end

      it 'do it false' do
        params.cart_item_ids = []
        expect(subject).to include(item2.uniqid)
      end

    end

    # Цепочки блоков
    context '.block chain' do
      before do
        recommender_block.update(rules: [
            {
                type: 'recommender',
                recommender: 'popular'
            },
            {
                type: 'recommender',
                recommender: 'popular_in_category'
            }
        ])
      end

      it 'do it' do
        expect(subject).to eq([item2.uniqid, item.uniqid])
      end

    end

  end

end
