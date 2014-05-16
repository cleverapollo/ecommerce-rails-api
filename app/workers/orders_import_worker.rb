class OrdersImportWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(opts)
    @current_shop = Shop.find_by!(uniqid: opts['shop_id'], secret: opts['shop_secret'])

    opts['orders'].each do |order|
      @current_order = order
      @current_user = fetch_user(@current_shop.id, @current_order['user_id'])

      next if order_already_saved?(order, @current_shop.id)

      items = []
      order['items'].each do |i|
        item = fetch_item(i, @current_shop.id)
        item.action_id = fetch_actions(item, @current_shop.id, @current_user.id)
        item.amount = i['amount'].to_i
        items << item
      end

      persist_order(@current_order, items, @current_shop.id, @current_user.id)
    end
  end

  def fetch_user(shop_id, user_id)
    u_s_r = UserShopRelation.find_by(shop_id: shop_id, uniqid: user_id.to_s)
    if u_s_r.present?
      return u_s_r.user
    else
      user = User.create
      user.ensure_linked_to_shop(@current_shop.id)
      UserShopRelation.create(shop_id: shop_id, uniqid: user_id.to_s, user_id: user.id)
      return user
    end
  end

  def fetch_item(item_raw, shop_id)
    item = Item.find_or_initialize_by(shop_id: shop_id, uniqid: item_raw['id'].to_s)

    return item unless item.new_record?
    item.update \
                price: item_raw['price'].to_f,
                category_uniqid: item_raw['category_id'],
                is_available: IncomingDataTranslator.is_available?(item_raw['is_available']),
                repeatable: item_raw['repeatable'].present?
    item
  end

  def fetch_actions(item, shop_id, user_id)
    action = Action.find_or_initialize_by(shop_id: shop_id, item_id: item.id, user_id: user_id)

    if action.persisted?
      action.increment!(:purchase_count)
    else
      action.update \
                    price: item.price,
                    category_uniqid: item.category_uniqid,
                    is_available: item.is_available,
                    repeatable: item.repeatable,
                    rating: 5.0,
                    purchase_count: 1

      MahoutAction.find_or_create_by(shop_id: shop_id, item_id: item.id, user_id: user_id)
    end

    action.id
  end

  def order_already_saved?(order, shop_id)
    Order.where(uniqid: order['id'].to_s, shop_id: shop_id).any?
  end

  def persist_order(order, items, shop_id, user_id)
    order = Order.create \
                         shop_id: shop_id,
                         user_id: user_id,
                         uniqid: order['id'],
                         date: order['date'].present? ? Time.at(order['date'].to_i) : Time.current,
                         recommended: false,
                         value: items.map{|i| (i.price.try(:to_f) || 0.0) * (i.amount.try(:to_f) || 1.0) }.sum

    items.each do |item|
      OrderItem.create \
                       order_id: order.id,
                       item_id: item.id,
                       action_id: item.action_id,
                       amount: item.amount
    end
  end
end
