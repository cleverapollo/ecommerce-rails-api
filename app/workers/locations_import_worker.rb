class LocationsImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  # Список городов из массива
  # @see http://docs.rees46.com/pages/viewpage.action?pageId=7640698
  # @param [Integer] shop_id
  # @param [Array<Hash<id,name,parent>>] locations
  def perform(shop_id, locations)

    # Создаем локации без указания родителя
    locations.each do |location|
      ShopLocation.insert_or_update(shop_id: shop_id, name: location[:name], external_id: location[:id])
    end

    # Делаем update локаций в которых указан родитель
    locations.each do |location|
      if location[:parent].present?
        l = ShopLocation.find_by(shop_id: shop_id, external_id: location[:parent])
        ShopLocation.where(shop_id: shop_id, external_id: location[:id]).update_all(parent_id: l.id, parent_external_id: location[:parent]) if l.present?
      end
    end
  rescue Exception => e
    ErrorsMailer.locations_import_error(Shop.find(shop_id), e.message).deliver_now
  end
end