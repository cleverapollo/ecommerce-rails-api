class Fixer
  def process
    fixing_shop = Shop.find(356)

    # получить товары, которые начинаются с буквы
    fixing_shop.items.where('uniqid ~* ?', '\D+\d+').find_each do |item|
      # Получить новый ид товара, который ему соответствует
      right_id = item.uniqid.gsub(/\D+/, '')
      new_item = Item.where(shop: fixing_shop.id, uniquid: right_id)

      # Заменяем историю
      Action.where(item: item).find_each do |action|
        break if Action.where(item: new_item, user: action.user)
        action.update(item: new_item)
      end

      [Interaction, MahoutAction, OrderItem].each do |refresh_class|
        puts 'Update '+refresh_class.inspect
        refresh_class.where(item: item.id).find_each do |entity|
          puts 'Update Entity '+entity.inspect
          entity.update(item: new_item)
        end
      end
    end
  end

  # Перенести историю со старых идентификаторов товаров Котофото на новые
  def process_by_noff
    shop = Shop.find(356)

    # Находим старые и новые товары
    item_ids_pairs = shop.items.pluck(:id, :uniqid)
    new_ids_pairs = []
    old_ids_pairs = []
    item_ids_pairs.each do |pair|
      if pair[1].match('\D+')
        old_ids_pairs << pair
      else
        new_ids_pairs << pair
      end
    end

    # Перебираем все старые товары
    old_ids_pairs.each do |old_item|
      old_id = old_item[0]
      old_uniqid = old_item[1]
      old_uniqid_stripped = old_uniqid.gsub(/\D+/, '')

      # Находим идентификатор нового товара
      new_id_pair = new_ids_pairs.select { |x| x[1] == old_uniqid_stripped  }.first
      if new_id_pair
        new_id = new_id_pair[0]

        # actions
        Action.where(shop_id: shop.id).where(item_id: old_id).find_each do |action|
          if Action.where(shop_id: shop.id).where(item_id: new_id).where(user_id: action.user_id).exists?
            action.destroy
          else
            action.update item_id: new_id
          end
        end

        # interactions
        Interaction.where(shop_id: shop.id).where(item_id: old_id).update_all item_id: new_id

        # mahout_actions + uniq #item_id#item_id
        MahoutAction.where(shop_id: shop.id).where(item_id: old_id).find_each do |mahout_action|
          if MahoutAction.where(shop_id: shop.id).where(item_id: new_id).where(user_id: mahout_action.user_id).exists?
            mahout_action.destroy
          else
            mahout_action.update item_id: new_id
          end
        end

        # order_items + # action_id
        OrderItem.where(item_id: old_id).find_each do |order_item|
          action_id = Action.where(item_id: new_id).where(user_id: order_item.order.user_id).limit(1).first.id
          order_item.update item_id: new_id, action_id: action_id
        end

      end

    end



  end


end