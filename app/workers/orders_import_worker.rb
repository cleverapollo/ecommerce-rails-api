##
# Класс, ответственный за импорт истории заказов магазина. Работает в фоне
#
class OrdersImportWorker
  class OrdersImportError < StandardError; end

  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

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

        @current_user = fetch_user(@current_shop, @current_order['user_id'], @current_order['user_email'])

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
      email = opts['errors_to'] || @current_shop.customer.email
      ErrorsMailer.orders_import_error(email, e.message, opts)
    end
  end

  def fetch_user(shop, user_id, user_email = nil)
    user_id = user_id.to_s
    if user_email.present?
      user_email = IncomingDataTranslator.email(user_email)
    end

    client = shop.clients.find_by(external_id: user_id)
    if client.present?
      client.update(email: user_email)
      client.user
    else
      user = User.create
      begin
        shop.clients.create(external_id: user_id, user_id: user.id, email: user_email)
      rescue ActiveRecord::RecordNotUnique => e
        user = shop.clients.find_by(external_id: user_id).user
      end
      user
    end
  end

  def fetch_item(item_raw, shop_id)
    if item_raw['id'].blank?
      raise OrdersImportError.new("В заказе ##{@current_order['id']} передан товар без ID")
    end

    item_raw['price'] = 0.0 if item_raw['price'].blank?

    # Вытаскиваем массив категорий, как бы их не назвал тот, кто вызвал импорт
    item_raw['categories'] = ([item_raw['category']] +
                              [item_raw['category_id']] +
                              [item_raw['category_uniqid']] +
                              [item_raw['categories']] +
                              [item_raw['categories']].try(:split, ',')).flatten.select(&:present?).uniq

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

  def fetch_actions(item, shop_id, user_id)\
    begin
      action = Action.find_or_initialize_by(shop_id: shop_id, item_id: item.id, user_id: user_id)

      if action.persisted?
        action.increment!(:purchase_count)
      else
        action.update(rating: 5.0, purchase_count: 1)

        MahoutAction.find_or_create_by(shop_id: shop_id, item_id: item.id, user_id: user_id)
      end
    rescue PG::UniqueViolation => e
      retry
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
