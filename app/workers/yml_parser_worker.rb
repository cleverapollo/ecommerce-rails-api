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
        item = Item.find_or_initialize_by(shop_id: shop.id, uniqid: i.fetch('id'))

        item.update(price: i.fetch('price'), 
                    category_uniqid: i['categoryId'],
                    categories: [i['categoryId']],
                    name: i['name'],
                    url: i['url'],
                    image_url: i['picture'],
                    is_available: i['available'] != 'false')
      rescue PG::UniqueViolation => e
        retry
      end
    end

    shop.update(yml_loaded: true)
  end
end
