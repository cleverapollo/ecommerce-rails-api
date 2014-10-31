class YmlParserWorker
  class Error < StandardError; end

  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform(shop_id)
    shop = Shop.find(shop_id)

    return if shop.yml_loaded

    if shop.yml_file_url.blank?
      raise YmlParserWorker::Error.new('У магазина не указана ссылка на YML-файл')
    end

    response = HTTParty.get(shop.yml_file_url, format: :xml)

    response['yml_catalog']['shop']['offers']['offer'].each do |i|
      begin
        item = Item.find_or_initialize_by(shop_id: shop.id, uniqid: i.fetch('id').to_s)

        item.price = i.fetch('price').to_f
        item.categories = [i['categoryId'].to_s.truncate(250)]
        item.name = i['name'].to_s.truncate(250)
        item.url = i['url'].to_s.truncate(250)
        item.image_url = (i['picture'].present? && i['picture'].is_a?(Array)) ? i['picture'].first.to_s.truncate(250) : i['picture'].to_s.truncate(250)
        item.is_available = ((i['available'] != 'false') && (i['available'] != false))
        item.save
      rescue PG::UniqueViolation => e
        retry
      end
    end
    shop.update(yml_loaded: true)
  rescue StandardError => e
    ErrorsMailer.yml_import_error('anton.zhavoronkov@mkechinov.ru', e, shop_id)
  end
end
