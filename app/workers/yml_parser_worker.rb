class YmlParserWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform(shop_id)
    shop = Shop.find(shop_id)

    return if shop.yml_loaded

    if shop.yml_file_url.blank?
      raise ArgumentError.new('У магазина не указана ссылка на YML-файл')
    end

    response = HTTParty.get(shop.yml_file_url)

    response['yml_catalog']['shop']['offers']['offer'].each do |i|
      begin
        item = Item.find_or_initialize_by(shop_id: shop.id, uniqid: i.fetch('id').to_s)

        item.price = i.fetch('price').to_f
        item.category_uniqid = i['categoryId'].to_s
        item.categories = [item.category_uniqid]
        item.name = i['name'].to_s
        item.url = i['url'].to_s
        item.image_url = (i['picture'].present? && i['picture'].is_a?(Array)) ? i['picture'].first.to_s : i['picture'].to_s
        item.is_available = ((i['available'] != 'false') && (i['available'] != false))
        item.save
      rescue PG::UniqueViolation => e
        retry
      end
    end

    shop.update(yml_loaded: true)
  end
end
