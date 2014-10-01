##
# Класс, выполняющий периодическую обработку YML-файлов магазинов.
#
class YmlSyncWorker
  # Обработка всех магазинов.
  def perform
    scoped_shops.find_each do |shop|
      perform_single(shop)
    end
  end

  # Обработка магазина. Создается хэш со всеми товарами магазина. 
  # Далее данные товаров синхронизируются с YML. Пока только доступность и цена.
  #
  # @param shop [Shop] магазин
  def perform_single(shop)
    items = {}
    shop.items.find_each do |item|
      items[item.uniqid] = item
    end

    parsed_yml_for(shop)['yml_catalog']['shop']['offers']['offer'].each do |i|
      if item = items[i.fetch('id').to_s]
        attributes = { 
          is_available: ((i['available'] != 'false') && (i['available'] != false)),
          price: i.fetch('price').to_f
        }

        changed = (item.is_available != attributes[:is_available])

        item.update(attributes)

        ItemsSynchronizeWorker.new.perform(item.id, attributes) if changed
      end
    end
  end

  private

  # Возвращает relation магазинов для обработки.
  # Это магазины с указанной ссылкой на YML, который был ранее успешно обработан.
  #
  # @private
  # @return [ActiveRecord::Relation] магазины для обработки
  def scoped_shops
    Shop.where(yml_loaded: true).where('yml_file_url IS NOT NULL').where("yml_file_url != ''")
  end

  # Возвращает распарсенное содержимое YML-файла магазина.
  #
  # @private
  # @param shop [Shop] магазин
  # @return [Hash] магазины для обработки
  def parsed_yml_for(shop)
    HTTParty.get(shop.yml_file_url).parsed_response
  end
end
