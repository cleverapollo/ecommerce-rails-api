# Импорт товаров

class ItemsImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_accessor :shop

  # @param [Integer] shop_id
  # @param [Array<Hash>] items
  # @param [Symbol] method Тип запроса для воркера, post, put, delete.
  def perform(shop_id, items, method = 'post')
    self.shop = Shop.find(shop_id)

    # Указываем, что идет обработка
    shop.update(yml_state: 'processing')

    # Помечаем как недоступные все товары
    if method == 'post'
      shop.items.available.update_all(is_available: false)
    end

    # Вставка, обновление
    if %w(post put).include?(method)
      process_items(items.map{|item| item.deep_symbolize_keys})
    end

    # Отмечает указанные товары как доступные
    if method == 'patch'
      # Те, которых нет в списке - отмечаем как недоступные
      shop.items.available.where.not(uniqid: items).update_all(is_available: false)

      # Отмечаем доступные
      shop.items.where(is_available: false, uniqid: items).update_all(is_available: true)
    end

    # Удаление
    if method == 'delete'
      delete_items(items)
    end

    # Обновляем дату yml
    shop.update(last_valid_yml_file_loaded_at: Time.now, yml_errors: 0, yml_state: nil, yml_loaded: true)

    # Записываем в лог число обработанных товаров
    CatalogImportLog.create shop_id: shop_id, success: true, message: "HTTP #{method} items #{items.count}", total: shop.items.count, available: shop.items.available.count, widgetable: shop.items.available.widgetable.count

    # Обновялем статистику по товарам
    ShopKPI.new(shop).calculate_products
  rescue Sidekiq::Shutdown => e
    Rollbar.info(e, 'Sidekiq shutdown, abort import items processing', shop_id: id)
    retry
  rescue Exception => e
    ErrorsMailer.products_import_error(self.shop, e.message).deliver_now
  ensure

    # Обработка закончилась
    shop.update(yml_state: nil)

    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end

  # Добавление / обновление товаров
  def process_items(items)

    # Указываем, что идет обработка
    shop.update(yml_state: 'processing')

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

      if item_params[:fashion].present?
        item_struct.fashion_sizes = item_params.fetch(:fashion)[:sizes]
        item_struct.fashion_gender = item_params.fetch(:fashion)[:gender]
        item_struct.fashion_wear_type = item_params.fetch(:fashion)[:type]
      end

      if item_params[:cosmetic].present?
        item_struct.cosmetic_gender = item_params[:cosmetic][:gender]
        item_struct.cosmetic_hypoallergenic = item_params[:cosmetic][:hypoallergenic] || nil
        item_struct.cosmetic_periodic = item_params[:cosmetic][:periodic] || nil
        if item_params[:cosmetic][:skin].present?
          item_struct.cosmetic_skin_part = item_params[:cosmetic][:skin][:part] if item_params[:cosmetic][:skin][:part].is_a?(Array)
          item_struct.cosmetic_skin_type = item_params[:cosmetic][:skin][:type] if item_params[:cosmetic][:skin][:type].is_a?(Array)
          item_struct.cosmetic_skin_condition = item_params[:cosmetic][:skin][:condition] if item_params[:cosmetic][:skin][:condition].is_a?(Array)
        end
        if item_params[:cosmetic][:hair].present?
          item_struct.cosmetic_hair_type = item_params[:cosmetic][:hair][:type] if item_params[:cosmetic][:hair][:type].is_a?(Array)
          item_struct.cosmetic_hair_condition = item_params[:cosmetic][:hair][:condition] if item_params[:cosmetic][:hair][:condition].is_a?(Array)
        end
        if item_params[:cosmetic][:nail].present?
          item_struct.cosmetic_nail = true
          item_struct.cosmetic_nail_type = item_params[:cosmetic][:nail][:type]
          item_struct.cosmetic_nail_color = item_params[:cosmetic][:nail][:polish_color] if item_params[:cosmetic][:nail][:type].present? && item_params[:cosmetic][:nail][:type] == 'polish'
        end
        if item_params[:cosmetic][:perfume].present?
          item_struct.cosmetic_perfume_aroma = item_params[:cosmetic][:perfume][:aroma] if item_params[:cosmetic][:perfume][:aroma].present?
          item_struct.cosmetic_perfume_family = item_params[:cosmetic][:perfume][:family] if item_params[:cosmetic][:perfume][:family].present?
        end
        item_struct.cosmetic_professional = item_params[:cosmetic][:professional] || nil
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
