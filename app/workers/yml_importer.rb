require 'csv'

class YmlImporter
  include Sidekiq::Worker
  include TempFiles

  sidekiq_options retry: false, queue: 'yml', failures: true, backtrace: true

  # Точка входа обработки YML
  # @param shop_id [Integer]
  # @param force [Boolean] Флаг, что насильно переимпортировать файл, игнорируя if-modified-since

  def perform(shop_id, force = false)
    current_shop = Shop.find(shop_id)

    # Указываем, что идет обработка
    current_shop.update(yml_state: 'processing')

    # Выходим, если файл уже обрабатывается и время старта меньше 1 дня
    return if !force && current_shop.yml_load_start_at.present? && current_shop.yml_load_start_at > 1.day.ago

    # Выходим, если файл не указан
    return if current_shop.yml_file_url.blank?

    # Проверяем, менялся ли файл: http://y.mkechinov.ru/issue/REES-3526
    # Если файл статический и у нас есть дата последней успешной обработки и запрос возвращает 304, то пропускаем
    # обработку, т.к. файл не изменился
    if current_shop.last_valid_yml_file_loaded_at.present? && force == false
      begin
        response = HTTParty.head(shop.yml_file_url, headers: {'If-Modified-Since' => shop.last_valid_yml_file_loaded_at.rfc822 }, timeout: 1)
        if response.code == 304 || ( response.headers && response.headers["last-modified"] && DateTime.parse(response.headers["last-modified"]) < shop.last_valid_yml_file_loaded_at )
          # Файл не изменился, пишем в лог и считаем, все обработано
          # Записываем в лог число обработанных товаров
          CatalogImportLog.create shop_id: shop_id, success: true, message: 'Not modified', total: current_shop.items.count, available: current_shop.items.available.count, widgetable: current_shop.items.available.widgetable.count
          return
        end
      rescue
        # Таймаут, значит живой скрипт, придется обрабатывать
      end
    end

    result = current_shop.import do
      # @type [Rees46ML::File] yml
      |yml|

      # @type shop [Rees46ML::Shop]
      shop = yml.shop
      fail Yml::InvalidYMLSyntax.new(I18n.t('yml_errors.no_shop_section')) if shop.nil?
      wear_types = WearTypeDictionary.index
      brands = Brand.all
      brands_usage = [] # Это для подсчета используемых брендов в каталоге магазина для модели ShopBrand
      offers_count = 0

      # Выходим, если не указан тег магазина в yml
      raise I18n.t('rees46_ml.error.invalid_shop', locale: current_shop.customer.language) if shop.nil?

      # Костыль, пропускаем магазины, в которых не указан available в YML
      skip_shop_items_available = []

      STDOUT.write "Prepare csv file:\n\r"
      temp_file do |file|
        t = Benchmark.realtime do
          csv_file file, col_sep: ',' do |csv|
            csv << Item.csv_header

            yml.offers.each_with_index do |offer, index|

              # Костыль для Roxy-Russia, у них отсутствует параметр available в YML
              if !offer.id.present? || !skip_shop_items_available.include?(current_shop.id) && !offer.available
                next
              end

              # Изменяем значение
              if skip_shop_items_available.include?(current_shop.id)
                offer.available = true
              end

              if offer.category_id.class == Set
                category_ids = offer.category_id.map { |id| shop.categories.path_to id }.flatten.uniq.compact
                # category_ids = offer.category_id.map { |id| shop.categories.path_to(id).join('.') }.uniq.compact
              else
                category_ids = shop.categories.path_to offer.category_id
              end
              category = shop.categories[offer.category_id].try(:name)
              location_ids = offer.locations.flat_map{ |location| shop.locations.path_to location.id }
              locations = {}
              offer.locations.each { |l| locations[l.id] = {}; locations[l.id]['price'] = l.prices.first.value.to_i if l.prices.any? } if offer.locations && offer.locations.any?

              offers_count += 1

              new_item = Item.build_by_offer(offer, category, wear_types, enable_description: current_shop.yml_description)

              # if new_item.url.present? && !Item.valid_url?(new_item.url)
              #   raise "Url not valid id: #{new_item.uniqid}, url: #{new_item.url}"
              # end

              new_item.id = index
              new_item.shop_id = shop_id
              new_item.is_available = offer.available
              new_item.category_ids = category_ids
              new_item.location_ids = location_ids.uniq if location_ids.compact.any? # Не пишем пустые массивы
              new_item.locations = locations
              if new_item.name.present? && (new_item.brand.nil? || !new_item.brand.present?)
                new_item.brand = brands.detect{ |brand| brand.match? new_item.name }.try(:name)
              end
              new_item.brand_downcase = new_item.brand.downcase if new_item.brand.present? && new_item.brand_downcase.nil?

              # Закоминаем для отчета по используемым брендам
              if new_item.brand_downcase.present?
                brands_usage << new_item.brand_downcase
              end

              csv << new_item.csv_row
              STDOUT.write "\rItems: #{ index }"
            end
          end
        end
        STDOUT.write "\rDone: #{t.round(2)} sec\n"

        attempt = 0

        begin
          Item.bulk_update shop_id, file
          ItemCategory.bulk_update shop_id, shop.categories
          ShopLocation.bulk_update shop_id, shop.locations
          ShopBrand.bulk_update shop_id, brands_usage.reduce(Hash.new(0)) { |a, b| a[b] += 1; a }.map { |k,v| [k,v] }
          # Обновялем статистику по товарам
          ShopKPI.new(current_shop).calculate_products

        rescue ActiveRecord::RecordNotUnique => e
          Rollbar.warning(e, "YML bulk operations error, attempt #{attempt}")
          attempt += 1
          retry if attempt < 10
        end

      end

    end

    if result
      # Записываем в лог число обработанных товаров
      CatalogImportLog.create shop_id: shop_id, success: true, message: 'Loaded', total: current_shop.items.count, available: current_shop.items.available.count, widgetable: current_shop.items.available.widgetable.count

      # Пересчитываем наличие отраслевых товаров
      current_shop.check_industrial_products

      # Переиндексируем полнотекстовый индекс, теперь для всех
      unless Rails.env.test?
        if current_shop.subscription_plans.product_search.active.paid.exists?
          Retailer::Products::ElasticSync.new(current_shop).perform
        end
      end

      current_shop.items.where.not(image_downloading_error: nil).update_all(image_downloading_error: nil)
      ImageDownloadLaunchWorker.perform_async(current_shop.id)
    end

    current_shop.update(have_industry_products: current_shop.items.where('is_cosmetic is true OR is_child is true OR is_fashion is true OR is_fmcg is true OR is_auto is true OR is_pets is true').where('(is_available = true) AND (ignored = false)').exists?)

  ensure
    # Обработка закончилась
    current_shop.update(yml_state: nil)

    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end
end
