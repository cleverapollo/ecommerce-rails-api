require 'rails_helper'

describe UserMerger do
  let!(:shop) { create(:shop) }
  let!(:master) { create(:user) }
  let!(:slave) { create(:user) }
  let!(:slave_shops_user) { create(:shops_user, shop: shop, user: slave) }
  let!(:slave_session) { create(:session, user: slave) }
  let!(:slave_action) { create(:action, user: slave, shop: shop, item_id: 1, view_count: 1) }
  let!(:master_action) { create(:action, user: master, shop: shop, item_id: 1, view_count: 1) }

  describe '.merge' do
    subject { UserMerger.merge(master, slave) }
    before { subject }

    it 'merges slave actions with master actions' do
      expect(master_action.reload.view_count).to eq(2)
    end

    it 'destroys slave actions' do
      expect(slave.actions.count).to eq(0)
    end

    it 'attaches slave shop relations to master' do
      expect(slave_shops_user.reload.user_id).to eq(master.id)
    end

    it 'attaches slave sessions to master' do
      expect(slave_session.reload.user_id).to eq(master.id)
    end

    it 'destroys slave user' do
      expect { User.find(slave.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
