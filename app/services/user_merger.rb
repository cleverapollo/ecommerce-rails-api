class UserMerger
  class << self
    def merge(master, slave)
      Session.where(user_id: slave.id).update_all(user_id: master.id)
      UserShopRelation.where(user_id: slave.id).update_all(user_id: master.id)

      Subscription.where(user_id: slave.id).each do |s|
        begin
          s.update(user_id: master.id)
        rescue ActiveRecord::RecordNotUnique
          s_m = Subscription.find_by(user_id: master.id, shop_id: s.shop_id)

          s.trigger_mails.update_all(subscription_id: s_m.id)
          s.destroy
        end
      end

      ShopsUser.where(user_id: slave.id).each do |su|
        if ShopsUser.where(user_id: master.id, shop_id: su.shop_id).any?
          ShopsUser.where(user_id: slave.id, shop_id: su.shop_id).delete_all
        else
          begin
            ShopsUser.where(user_id: slave.id, shop_id: su.shop_id).update_all(user_id: master.id)
          rescue ActiveRecord::RecordNotUnique
          end
        end
      end

      slave.actions.each do |slave_action|
        master_action = Action.find_by(user_id: master.id, shop_id: slave_action.shop_id, item_id: slave_action.item_id)

        if master_action.present?
          master_action.update \
            view_count: master_action.view_count + slave_action.view_count,
            cart_count: master_action.cart_count + slave_action.cart_count,
            purchase_count: master_action.purchase_count + slave_action.purchase_count,
            view_date: [master_action.view_date, slave_action.view_date].compact.max,
            cart_date: [master_action.cart_date, slave_action.cart_date].compact.max,
            purchase_date: [master_action.purchase_date, slave_action.purchase_date].compact.max,
            rating: [master_action.rating, slave_action.rating].compact.max,
            timestamp: [master_action.timestamp, slave_action.timestamp].compact.max,
            recommended_by: master_action.recommended_by.present? ? master_action.recommended_by : slave_action.recommended_by

          slave_action.destroy
        else
          begin
            slave_action.update(user_id: master.id)
          rescue ActiveRecord::RecordNotUnique
          end
        end
      end

      Interaction.where(user_id: slave.id).update_all(user_id: master.id)
      Order.where(user_id: slave.id).update_all(user_id: master.id)

      MahoutAction.where(user_id: slave.id).find_each do |ma|
        if MahoutAction.where(user_id: master.id, item_id: ma.item_id).none?
          begin
            ma.update(user_id: master.id)
          rescue ActiveRecord::RecordNotUnique
          end
        else
          ma.destroy
        end
      end

      begin
        slave.reload.destroy
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordNotFound

      end
    end
  end
end
