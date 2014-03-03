require 'spec_helper'

describe UserMerger do
  describe '.merge' do
    before do
      @master = create(:user)
      @slave = create(:user)
      @shop = create(:shop)
      @slave_shop_relation = create(:user_shop_relation, user: @slave, shop: @shop)
      @slave_session = create(:session, user: @slave)
      @slave_action = create(:action, user: @slave, shop: @shop, item_id: 1, view_count: 1)
      @master_action = create(:action, user: @master, shop: @shop, item_id: 1, view_count: 1)

      UserMerger.merge(@master, @slave)
    end

    it 'merges slave actions with master actions' do
      expect(@master_action.reload.view_count).to eq(2)
    end

    it 'destroys slave actions' do
      expect(@slave.actions.count).to eq(0)
    end

    it 'attaches slave shop relations to master' do
      expect(@slave_shop_relation.reload.user_id).to eq(@master.id)
    end

    it 'attaches slave sessions to master' do
      expect(@slave_session.reload.user_id).to eq(@master.id)
    end

    it 'destroys slave user' do
      expect { User.find(@slave.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
