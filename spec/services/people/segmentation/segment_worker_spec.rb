require 'rails_helper'

describe People::Segmentation::SegmentWorker do

  describe '.perform' do

    let!(:shop) { create(:shop) }
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:user3) { create(:user) }
    let!(:user4) { create(:user) }
    let!(:user5) { create(:user) }
    let!(:segment) { create(:segment, name: 'test', shop: shop, segment_type: Segment::TYPE_STATIC) }
    let!(:client1) { create(:client, user: user1, shop: shop, email: 'test@test.com') }
    let!(:shop_email1) { create(:shop_email, shop: shop, email: client1.email, triggers_enabled: false, digests_enabled: false, segment_ids: [segment.id]) }
    let!(:client2) { create(:client, user: user2, shop: shop, email: 'test2@test.com', segment_ids: [segment.id]) }
    let!(:shop_email2) { create(:shop_email, shop: shop, email: client2.email, triggers_enabled: true, digests_enabled: true, segment_ids: [segment.id]) }
    let!(:client3) { create(:client, user: user3, shop: shop, segment_ids: [segment.id]) }
    let!(:client4) { create(:client, user: user4, shop: shop, web_push_enabled: true, segment_ids: [segment.id]) }
    let!(:client5) { create(:client, user: user5, shop: shop) }
    let!(:order1) { create(:order, user: user1, value: 1000, date: 2.months.ago, shop: shop, uniqid: '1' )}
    let!(:order2) { create(:order, user: user1, value: 1000, date: 2.months.ago, shop: shop, uniqid: '2' )}
    let!(:order3) { create(:order, user: user2, value: 1000, date: 2.months.ago, shop: shop, uniqid: '3' )}
    let!(:order4) { create(:order, user: user3, value: 1000, date: 2.months.ago, shop: shop, uniqid: '4' )}
    let!(:order5) { create(:order, user: user4, value: 5, date: 2.months.ago, shop: shop, uniqid: '5' )}

    it 'calculate segment statistic' do

      People::Segmentation::SegmentWorker.new.perform(segment)

      expect(segment.reload.client_count).to be(4)
      expect(segment.reload.with_email_count).to be(2)
      expect(segment.reload.trigger_client_count).to be(1)
      expect(segment.reload.digest_client_count).to be(1)
      expect(segment.reload.web_push_client_count).to be(1)
    end


  end

end
