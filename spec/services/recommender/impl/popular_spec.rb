require 'rails_helper'

describe Recommender::Impl::Popular do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:random_items) do
    items = []
    10.times do |i|
      items[i] = create(:item, shop: shop, sr: rand(0.7))
      create_action(items[i])
    end
    items
  end

  let!(:item1) do
    item = create(:item, shop: shop, sr: 0.9)
    create_action(item, true)
    item
  end

  let!(:params) { OpenStruct.new(shop: shop, user: user, limit: 7, type: 'popular') }

  def create_action(item, is_buy = false)
    a = item.actions.new(user: create(:user),
                         shop: shop,
                         timestamp: 1.day.ago.to_i,
                         rating: Actions::View::RATING)

    if is_buy
      a.purchase_count = 1
      a.rating = Actions::Purchase::RATING
    end
    a.save
  end

  describe '#items_to_weight' do
    context 'when no category provided' do

      subject { Recommender::Impl::Popular.new(params) }

      context 'when there is enough purchases' do
        before { create_action(item1, true) }


        it 'returns most frequently buyed items' do
          expect(subject.recommendations).to include(item1.uniqid)
        end
      end

      # context 'when there is not enough purchases' do
      #   before { create_action(item1) }
      #
      #   it 'returns items by rating' do
      #     expect(subject.recommendations).to include(item1.uniqid)
      #   end
      # end
    end


    # context 'when category provided' do
    #   before { params[:categories] = item1.categories }
    #
    #   subject { Recommender::Impl::Popular.new(params) }
    #
    #   context 'when there is enough purchases' do
    #     before { create_action(item1, true) }
    #
    #     it 'returns most frequently buyed items' do
    #       expect(subject.recommendations).to include(item1.uniqid)
    #     end
    #   end
    #
    #   context 'when there is not enough purchases' do
    #     before { create_action(item1) }
    #
    #     it 'returns items by rating' do
    #       expect(subject.recommendations).to include(item1.uniqid)
    #     end
    #   end
    # end

  end
end
