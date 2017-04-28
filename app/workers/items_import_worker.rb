# Импорт товаров

class ItemsImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_accessor :shop

  # @param [Integer] shop_id
  # @param [Array<Hash>] items
  # @param [Symbol] method Тип запроса для воркера, post, put, delete.
  def perform(shop_id, items, method = :post)
    self.shop = Shop.find(shop_id)

    # Вставка, обновление
    if [:post, :put].include?(method)
      process_items(items.map{|item| item.deep_symbolize_keys})
    end

    # Удаление
    if method == :delete
      delete_items(items)
    end
  rescue Exception => e
    ErrorsMailer.products_import_error(self.shop, e.message).deliver_now
  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end

  # Добавление / обновление товаров
  def process_items(items)
    items.map do |item_params|
      item_struct = OpenStruct.new(item_params)
      item_struct.uniqid = item_params.fetch(:id)
      item_struct.category_ids = item_params.fetch(:categories)
      item_struct.is_available = !!item_params.fetch(:available)
      item_struct.image_url = item_params.fetch(:picture)

      if item_params[:locations].present? && item_params[:locations].is_a?(Array)
        item_struct.location_ids = []
        item_params[:locations].each do |location|
          item_struct.location_ids << location[:location]
        end
        item_struct.locations = item_params[:locations]
      end

      if item_params.fetch(:fashion).present?
        item_struct.fashion_sizes = item_params.fetch(:fashion)[:sizes]
        item_struct.fashion_gender = item_params.fetch(:fashion).fetch(:gender)
        item_struct.fashion_wear_type = item_params.fetch(:fashion).fetch(:type)
      end
      item_struct.amount = 0
      item_struct
    end.each do |item_struct|
      Item.fetch(shop.id, item_struct)
    end
  end

  # Отмечаем товары как недоступные
  def delete_items(items)
    Item.where(shop_id: shop.id, uniqid: items, is_available: true).update_all(is_available: false)
  end
end
