##
# Класс, ответственный за импорт истории заказов магазина. Работает в фоне
#
class OrdersImportWorker
  class OrdersImportError < StandardError; end
  class OrdersImportOrderWithoutItemError < StandardError; end

  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_accessor :mahout_service
  attr_accessor :import_status_messages

  def perform(opts)
    @import_status_messages = {
        order_without_id: [],       # put here order row
        order_without_user_id: [],  # put here order row
        order_without_items: [],    # put here order row
        order_item_without_id: []   # put here order row
    }

    begin
      @current_shop = Shop.find_by!(uniqid: opts['shop_id'], secret: opts['shop_secret'])
      if @current_shop.deactivated?
        return false
      end

      if opts['orders'].nil? || !opts['orders'].is_a?(Array)
        raise OrdersImportError.new('Не передан массив заказов')
      end
      if opts['orders'].none?
        raise OrdersImportError.new('Пустой массив заказов')
      end

      # Connect to BRB
      @mahout_service = MahoutService.new(@current_shop.brb_address) if @current_shop.use_brb?
      @orders_count = 0

      opts['orders'].each do |order|
        @current_order = order

        if @current_order['id'].blank?
          @import_status_messages[:order_without_id] << @current_order
          next
          # raise OrdersImportError.new('Передан заказ без ID')
        end

        if @current_order['user_id'].blank?
          @import_status_messages[:order_without_user_id] << @current_order
          next
          # raise OrdersImportError.new("Передан заказ ##{@current_order['id']} без ID пользователя")
        end

        @current_user = fetch_user(@current_shop, @current_order['user_id'], IncomingDataTranslator.email(@current_order['user_email']))

        next if order_already_saved?(order, @current_shop.id)

        items = []

        if @current_order['items'].nil? || @current_order['items'].none?
          @import_status_messages[:order_without_items] << @current_order
          next
          # raise OrdersImportError.new("Передан заказ ##{@current_order['id']} без массива товаров")
        end

        begin
          order['items'].each do |i|
            item = fetch_item(i, @current_shop.id)
            item.amount = i['amount'].to_i
            items << item
          end
        rescue OrdersImportOrderWithoutItemError => e
          # Если проблема с поиском товара в заказе, то пропускаем такой заказ
          @import_status_messages[:order_item_without_id] << @current_order
          next
        end

        persist_order(@current_order, items, @current_shop.id, @current_user.id)
        @orders_count += 1
      end

      # Report import results errors
      ErrorsMailer.orders_import_processed(@current_shop, @import_status_messages)

      @current_shop.update(last_orders_import_at: Time.now)
    rescue OrdersImportError => e
      email = opts['errors_to'] || @current_shop.customer.email
      opts['shop'] = current_shop
      ErrorsMailer.orders_import_error(email, e.message, opts).deliver_now
    end

  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end

  # Упрощенный поиск пользователя для импорта
  def fetch_user(shop, user_id, user_email = nil)
    user_id = user_id.to_s

    client = shop.clients.find_by(external_id: user_id)
    if client.present?
      client.update(email: user_email) if user_email.present?
      user = client.user
    else
      user = User.create
      begin
        client = shop.clients.create(external_id: user_id, user_id: user.id, email: user_email)
      rescue ActiveRecord::RecordNotUnique => e
        client = shop.clients.find_by(external_id: user_id)
      end
    end

    if user_email.present?
      user = UserMerger.merge_by_mail(shop, client, user_email)

      # Добавляем в список email магазина
      ShopEmail.fetch(shop, user_email, client: client)
    end

    user
  end

  # Упрощенный поиск товара для импорта
  def fetch_item(item_raw, shop_id)
    if item_raw['id'].blank?
      raise OrdersImportOrderWithoutItemError.new("В заказе ##{@current_order['id']} передан товар без ID")
    end

    item_raw['price'] = 0.0 if item_raw['price'].blank?

    # Вытаскиваем массив категорий, как бы их не назвал тот, кто вызвал импорт
    item_raw['category_ids'] = ([item_raw['category']] +
        [item_raw['category_id']] +
        [item_raw['category_uniqid']] +
        [item_raw['categories']] +
        [item_raw['categories']].try(:split, ',')).flatten.select(&:present?).uniq

    item = Item.find_or_initialize_by(shop_id: shop_id, uniqid: item_raw['id'].to_s)

    if item.new_record?
      item_proxy = OpenStruct.new(item_raw)
      item_proxy[:is_available] = true if item_proxy[:is_available].blank?
      item.merge_attributes(item_proxy)
      begin
        item.save!
      rescue PG::UniqueViolation => e
        item = Item.find_by(shop_id: shop_id, uniqid: item_raw['id'].to_s)
      rescue ActiveRecord::RecordNotUnique => e
        item = Item.find_by(shop_id: shop_id, uniqid: item_raw['id'].to_s)
      end
    end

    item
  end

  def order_already_saved?(order, shop_id)
    Order.where(uniqid: order['id'].to_s, shop_id: shop_id).exists?
  end

  def persist_order(order, items, shop_id, user_id)
    order = Order.create!(shop_id: shop_id,
                         user_id: user_id,
                         uniqid: order['id'],
                         date: order['date'].present? ? Time.at(order['date'].to_i) : Time.current,
                         recommended: false,
                         value: items.map { |i| (i.price.try(:to_f) || 0.0) * (i.amount.try(:to_f) || 1.0) }.sum,
                         common_value: items.map { |i| (i.price.try(:to_f) || 0.0) * (i.amount.try(:to_f) || 1.0) }.sum)

    items.each do |item|
      OrderItem.create!(order_id: order.id,
                       item_id: item.id,
                       shop_id: shop_id,
                       amount: item.amount)
    end
  rescue
    ActiveRecord::RecordNotUnique
  end
end
