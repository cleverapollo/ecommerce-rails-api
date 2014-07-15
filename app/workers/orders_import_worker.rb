class OrdersImportWorker
  class OrdersImportError < StandardError; end

  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(opts)
    begin
      @current_shop = Shop.find_by!(uniqid: opts['shop_id'], secret: opts['shop_secret'])

      if opts['orders'].nil? || !opts['orders'].is_a?(Array)
        raise OrdersImportError.new('Не передан массив заказов')
      end
      if opts['orders'].none?
        raise OrdersImportError.new('Пустой массив заказов')
      end

      opts['orders'].each do |order|
        @current_order = order

        if @current_order['id'].blank?
          raise OrdersImportError.new('Передан заказ без ID')
        end

        if @current_order['user_id'].blank?
          raise OrdersImportError.new("Передан заказ ##{@current_order['id']} без ID пользователя")        
        end

        @current_user = fetch_user(@current_shop.id, @current_order['user_id'], @current_order['user_email'])

        next if order_already_saved?(order, @current_shop.id)

        items = []

        if @current_order['items'].nil? || @current_order['items'].none?
          raise OrdersImportError.new("Передан заказ ##{@current_order['id']} без массива товаров")
        end

        order['items'].each do |i|
          item = fetch_item(i, @current_shop.id)
          item.action_id = fetch_actions(item, @current_shop.id, @current_user.id)
          item.amount = i['amount'].to_i
          items << item
        end

        persist_order(@current_order, items, @current_shop.id, @current_user.id)
      end
    rescue OrdersImportError => e
      ErrorsMailer.orders_import_error(@current_shop.customer, e.message)
    end
  end

  def fetch_user(shop_id, user_id, user_email = nil)
    if user_email.present?
      user_email = IncomingDataTranslator.email(user_email)
    end

    u_s_r = UserShopRelation.find_by(shop_id: shop_id, uniqid: user_id.to_s)
    if u_s_r.present?
      return u_s_r.user
    else
      user = User.create
      user.ensure_linked_to_shop(@current_shop.id)
      begin
        UserShopRelation.create(shop_id: shop_id, uniqid: user_id.to_s, user_id: user.id, email: user_email)
      rescue PG::UniqueViolation => e
        user = UserShopRelation.find_by(shop_id: shop_id, uniqid: user_id.to_s).user
      end
      return user
    end
  end

  def fetch_item(item_raw, shop_id)
    if item_raw['id'].blank?
      raise OrdersImportError.new("В заказе ##{@current_order['id']} передан товар без ID")
    end
    if item_raw['price'].blank?
      raise OrdersImportError.new("В заказе ##{@current_order['id']} передан товар ##{item_raw['id']} без цены")
    end

    item = Item.find_or_initialize_by(shop_id: shop_id, uniqid: item_raw['id'].to_s)

    if item.new_record?
      item_proxy = OpenStruct.new(item_raw)
      item.merge_attributes(item_proxy)
      begin
        item.save!
      rescue PG::UniqueViolation => e
        item = Item.find_by(shop_id: shop_id, uniqid: item_raw['id'].to_s)
      end
    end

    item
  end

  def fetch_actions(item, shop_id, user_id)
    action = Action.find_or_initialize_by(shop_id: shop_id, item_id: item.id, user_id: user_id)

    if action.persisted?
      action.increment!(:purchase_count)
    else
      action.update(item.attributes_for_actions.merge(rating: 5.0, purchase_count: 1))

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
