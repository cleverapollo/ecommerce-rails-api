namespace :reorganizations do
  desc "Reorganizes categories in Action and Item"
  task categories: :environment do
    Item.find_in_batches do |batch|
      Item.connection.execute("
        UPDATE items
        SET categories = ARRAY[category_uniqid]
        WHERE category_uniqid is not null AND category_uniqid != ''
        AND id IN (#{batch.map(&:id).join(',')})
      ")
    end

    Action.find_in_batches do |batch|
      Action.connection.execute("
        UPDATE actions
        SET categories = ARRAY[category_uniqid]
        WHERE category_uniqid is not null AND category_uniqid != ''
        AND id IN (#{batch.map(&:id).join(',')})
      ")
    end
  end


  desc "Recalculate orders"
  task recalculate_orders: :environment do
    Order.includes(order_items: :item).where(common_value: 0.0, recommended_value: 0.0).where("date >= ?", 1.month.ago).find_each(batch_size: 100) do |order|
      next if order.user.blank? || order.shop.blank?
      items = order.order_items.map{|oi| i = oi.item; i.amount = oi.amount; i }
      values = Order.order_values(order.shop, order.user, items)
      order.update(
        common_value: values[:common_value],
        recommended_value: values[:recommended_value],
        value: values[:value],
        recommended: (values[:recommended_value] > 0)
      )
    end
  end

  desc "Merge user_shop_relations into shops_users"
  task merge_user_shop_relations_into_shops_users: :environment do
    Shop.find_each do |shop|
      shops_users = {}
      shop.shops_users.find_each(batch_size: 5_000) do |s_u|
        shops_users[s_u.user_id] = s_u
      end

      UserShopRelation.where(shop_id: shop.id).find_each(batch_size: 5_000) do |u_s_r|
        if s_u = shops_users[u_s_r.user_id]
          email = u_s_r.email.present? ? u_s_r.email : s_u.email
          s_u.update_columns(external_id: u_s_r.uniqid, email: email)
        else
          s_u = shop.shops_users.create!(external_id: u_s_r.uniqid, email: u_s_r.email, user_id: u_s_r.user_id)
          shops_users[u_s_r.user_id] = s_u
        end
      end
    end
  end

  desc "Merge audiences into shops_users"
  task merge_audiences_into_shops_users: :environment do
    Audience.find_each do |audience|
      s_u = if audience.user_id.present?
        ShopsUser.find_by(shop_id: audience.shop_id, user_id: audience.user_id)
      else
        ShopsUser.find_by(shop_id: audience.shop_id, external_id: audience.external_id)
      end

      if s_u.present?
        s_u.update_columns(email: audience.email, digests_enabled: audience.active)
      else
        user_id = audience.user_id || User.create.id
        ShopsUser.create!(shop_id: audience.shop_id, external_id: audience.external_id, email: audience.email, user_id: user_id, digests_enabled: audience.active)
      end
    end
  end

  desc "Merge subscriptions into shops_users"
  task merge_subscriptions_into_shops_users: :environment do
    Subscription.find_each do |subscription|
      if s_u = subscription.shop.shops_users.find_by(user_id: subscription.user_id)
        s_u.update_columns(
          email: (s_u.email.present? ? s_u.email : subscription.email),
          subscription_popup_showed: true,
          triggers_enabled: subscription.active,
          last_trigger_mail_sent_at: subscription.dont_disturb_until
        )
      end
    end
  end
end






























