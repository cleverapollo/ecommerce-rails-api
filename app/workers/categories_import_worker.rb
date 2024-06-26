class CategoriesImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  # Список категорий из массива
  # @see http://docs.rees46.com/pages/viewpage.action?pageId=7640694
  # @param [Integer] shop_id
  # @param [Array<Hash<id,name,parent>>] categories
  def perform(shop_id, categories)
    categories = categories.map {|c| c.with_indifferent_access }

    # Создаем локации без указания родителя
    categories.each do |category|
      begin
        ItemCategory.insert_or_update(shop_id: shop_id, name: category[:name], external_id: category[:id])
      rescue Exception => e
        raise "#{e.message}, params: #{category.to_json}"
      end
    end

    # Делаем update локаций в которых указан родитель
    categories.each do |category|
      if category[:parent].present?
        l = ItemCategory.find_by(shop_id: shop_id, external_id: category[:parent])
        ItemCategory.where(shop_id: shop_id, external_id: category[:id]).update_all(parent_id: l.id, parent_external_id: category[:parent]) if l.present?
      end
    end
  rescue Exception => e
    ErrorsMailer.categories_import_error(Shop.find(shop_id), e.message).deliver_now
  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end
end
