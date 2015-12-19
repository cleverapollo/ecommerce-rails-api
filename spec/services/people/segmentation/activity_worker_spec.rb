require 'rails_helper'

describe People::Segmentation::ActivityWorker do

  describe '.perform' do

    let!(:shop) { create(:shop) }
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:user3) { create(:user) }
    let!(:user4) { create(:user) }
    let!(:user5) { create(:user) }
    let!(:client1) { create(:client, user: user1, shop: shop) }
    let!(:client2) { create(:client, user: user2, shop: shop) }
    let!(:client3) { create(:client, user: user3, shop: shop) }
    let!(:client4) { create(:client, user: user4, shop: shop) }
    let!(:client5) { create(:client, user: user5, shop: shop) }
    let!(:order1) { create(:order, user: user1, value: 1000, date: 2.months.ago, shop: shop, uniqid: '1' )}
    let!(:order2) { create(:order, user: user1, value: 1000, date: 2.months.ago, shop: shop, uniqid: '2' )}
    let!(:order3) { create(:order, user: user2, value: 1000, date: 2.months.ago, shop: shop, uniqid: '3' )}
    let!(:order4) { create(:order, user: user3, value: 1000, date: 2.months.ago, shop: shop, uniqid: '4' )}
    let!(:order5) { create(:order, user: user4, value: 5, date: 2.months.ago, shop: shop, uniqid: '5' )}

    it 'calculates segments and saves it to database' do

      People::Segmentation::ActivityWorker.new(shop).perform

      expect(People::Segmentation::Activity.new(client1.reload).group_a?).to be_truthy
      expect(People::Segmentation::Activity.new(client2.reload).group_b?).to be_truthy
      expect(People::Segmentation::Activity.new(client3.reload).group_b?).to be_truthy
      expect(People::Segmentation::Activity.new(client4.reload).group_c?).to be_truthy
      expect(People::Segmentation::Activity.new(client5.reload).inactive?).to be_truthy

    end


  end

end