require 'rails_helper'

RSpec.describe Recommender, :type => :model do
  let!(:shop) { create(:shop) }
  let!(:item) { create(:item, shop: shop) }
  let!(:user) { create(:user) }
  let!(:recommender_block) { create(:recommender_block, shop: shop, rules: []) }

  let(:params) { OpenStruct.new(shop: shop, user: user, item: item) }

  before { allow_any_instance_of(RecAlgo::Impl::Popular).to receive(:recommendations).and_return([item.uniqid]) }

  subject { recommender_block.recommends(params) }

  context '.rules' do

    context '.condition' do
      before do
        params.cart_item_ids = [item.id]
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

              ]
          },
        ])
      end

      it 'do it true' do
        expect(subject).to include(item.uniqid)
      end

    end

  end

end
