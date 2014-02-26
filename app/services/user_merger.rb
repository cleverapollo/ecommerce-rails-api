class UserMerger
  class << self
    def merge(master, slave)
      Session.where(user_id: slave.id).update_all(user_id: master.id)
      UserShopRelation.where(user_id: slave.id).update_all(user_id: master.id)

      slave.actions.each do |slave_action|
        master_action = Action.find_by(user_id: master.id, shop_id: slave_action.shop_id, item_id: slave_action.item_id)

        if master_action.present?
          master_action.update \
            view_count: master_action.view_count + slave_action.view_count,
            cart_count: master_action.cart_count + slave_action.cart_count,
            purchase_count: master_action.purchase_count + slave_action.purchase_count,
            view_date: [master_action.view_date, slave_action.view_date].max,
            cart_date: [master_action.cart_date, slave_action.cart_date].max,
            purchase_date: [master_action.purchase_date, slave_action.purchase_date].max,
            rating: [master_action.rating, slave_action.rating].max,
            timestamp: [master_action.timestamp, slave_action.timestamp].max,
            recommended_by: master_action.recommended_by || slave_action.recommended_by

          slave_action.destroy
        else
          slave_action.update(user_id: master.id)
        end
      end

      slave.destroy
    end
  end
end
