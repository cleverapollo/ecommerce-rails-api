require 'rails_helper'

RSpec.describe RecommenderBlock, :type => :model do
  let!(:shop) { create(:shop) }
  let!(:item) { create(:item, shop: shop) }
  let!(:item2) { create(:item, shop: shop) }
  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }
  let!(:recommender_block) { create(:recommender_block, shop: shop, rules: []) }

  # Часть параметров указывается абстрактно, т.к. создаем mock объекты для рекомендеров.
  let(:params) { OpenStruct.new(ssid: session.code, categories: %w(test)) }

  # Создаем mock объекты, т.к. в этом тесте нам не важно как работает сам рекомендер
  before { allow_any_instance_of(RecAlgo::Impl::Popular).to receive(:recommendations).and_return([item.uniqid]) }
  before { allow_any_instance_of(RecAlgo::Impl::PopularInCategory).to receive(:recommendations).and_return([item2.uniqid]) }

  subject { recommender_block.recommends(params) }

  context '.rules' do

    # Условия в выборке пути
    context '.condition' do

      # Товар в корзине
      context '.cart' do
        before do
          recommender_block.update(rules: [
            {
                type: 'condition',
                condition: 'cart',
                yes: [{ type: 'recommender', recommender: 'popular' }],
                no: [{type: 'recommender', recommender: 'popular_in_category' }]
            },
          ])
        end

        it 'do it true' do
          params.item_id = item2.uniqid
          ClientCart.create!(shop: shop, user: user, items: [item2.id])
          expect(subject).to include(item.uniqid)
        end

        it 'do it false' do
          params.item_id = item.uniqid
          expect(subject).to include(item2.uniqid)
        end
      end

      # По правилам для юзера
      context '.user' do
        before do
          recommender_block.update(rules: [
              {
                  type: 'condition',
                  condition: 'user',
                  yes: [{type: 'recommender', recommender: 'popular'}],
                  no: []
              }
          ])
        end

        # Пол
        it 'do it true with gender' do
          user.update(gender: 'm')
          recommender_block.rules[0][:gender] = 'm'
          recommender_block.save
          expect(subject).to include(item.uniqid)
        end

        # Дети
        it 'do it true with children gender' do
          recommender_block.rules[0][:children] = {gender: 'm'}
          recommender_block.save
          user.update(children: [{gender: 'm', age_min: 1, age_max: 2.25}])
          expect(subject).to include(item.uniqid)
        end

        it 'do it true with children age' do
          recommender_block.rules[0][:children] = {age_min: '1', age_max: '3'}
          recommender_block.save
          user.update(children: [{gender: 'm', age_min: 1, age_max: 2.25}])
          expect(subject).to include(item.uniqid)
        end

        it 'do it true with children' do
          recommender_block.rules[0][:children] = {gender: 'm', age_min: '1', age_max: '3'}
          recommender_block.save
          user.update(children: [{gender: 'm', age_min: 1, age_max: 2.25}])
          expect(subject).to include(item.uniqid)
        end

        it 'do it true with gender && children' do
          recommender_block.rules[0][:children] = {gender: 'm'}
          recommender_block.rules[0][:gender] = 'm'
          recommender_block.save
          user.update(gender: 'm', children: [{gender: 'm', age_min: 1, age_max: 2.25}])
          expect(subject).to include(item.uniqid)
        end

        # Авто
        it 'do it true with car' do
          recommender_block.rules[0][:auto_brand] = ['audi']
          recommender_block.save
          user.update(compatibility: [{brand: 'audi'}])
          expect(subject).to include(item.uniqid)
        end

        it 'do it false with car' do
          recommender_block.rules[0][:auto_brand] = ['audi']
          recommender_block.save
          user.update(compatibility: [{brand: 'bmw'}])
          expect(subject).to eq([])
        end

        # Other
        it 'do it false' do
          recommender_block.rules[0][:gender] = 'm'
          recommender_block.save
          expect(subject).to_not include(item.uniqid)
        end
      end

      # Товар в категории
      context '.item_category' do
        before do
          params.item_id = item2.uniqid
          recommender_block.update(rules: [
              {
                  type: 'condition',
                  condition: 'item_category',
                  categories: %w(1 2),
                  yes: [{type: 'recommender', recommender: 'popular'}],
                  no: []
              }
          ])
        end

        it 'do it true' do
          item2.update(category_ids: %w(2 3))
          expect(subject).to include(item.uniqid)
        end

        it 'do it false' do
          item.update(category_ids: %w(3 4))
          expect(subject).to eq([])
        end
      end

      # Категория
      context '.category' do
        before do
          params.item_id = item2.uniqid
          recommender_block.update(rules: [
            {
                type: 'condition',
                condition: 'category',
                category_id: '1',
                yes: [{ type: 'recommender', recommender: 'popular' }],
                no: []
            },
          ])
        end

        it 'do it true' do
          item2.update(category_ids: %w(1))
          params.categories = %w(1 3)
          expect(subject).to include(item.uniqid)
        end

        it 'do it false' do
          expect(subject).to eq([])
        end
      end

    end

    # Цепочки блоков
    context '.block chain' do
      before do
        recommender_block.update(rules: [
            { type: 'recommender', recommender: 'popular' },
            { type: 'recommender', recommender: 'popular_in_category' }
        ])
      end

      it 'do it' do
        expect(subject).to eq([item.uniqid, item2.uniqid])
      end

      it 'do it limit 1' do
        recommender_block.update(limit: 1)
        expect(subject).to eq([item.uniqid])
      end

    end

  end

end
