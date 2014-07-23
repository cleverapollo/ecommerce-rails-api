class InsalesExporter
  APP_LOGIN = 'rees46'
  APP_SECRET = 'c940a1b06136d578d88999c459083b78'

  class InsalesExportError < StandardError; end

  def initialize(shop)
    if shop.insales_shop.blank?
      raise InsalesExportError.new('Это не InSales-магазин')
    end

    @shop = shop
    @insales_shop = shop.insales_shop
    @url = "http://#{@insales_shop.insales_shop}"
    @auth = { username: APP_LOGIN, password: Digest::MD5.hexdigest(@insales_shop.token + APP_SECRET) }
    @processed_orders = []
  end

  def perform
    initialize_categories_cache

    page = 1; per_page = 25
    loop do
      resp = HTTParty.get("#{@url}/admin/orders.xml?per_page=#{per_page}&page=#{page}", 
                          basic_auth: @auth, 
                          headers: { 'Content-Type' => 'application/xml' })

      @orders = resp['orders']

      if @orders.blank? || @orders.none?
        break;
      else
        process_orders
        page += 1
      end
    end

    send_orders
  end

  def initialize_categories_cache
    @categories_cache = {}

    page = 1; per_page = 250
    loop do
      resp = HTTParty.get("#{@url}/admin/products.xml?per_page=#{per_page}&page=#{page}", 
                          basic_auth: @auth, 
                          headers: { 'Content-Type' => 'application/xml' })

      items = resp['products']

      if items.blank? || items.none?
        break
      else
        items.each do |item|
          @categories_cache[item['id']] = item['category_id']
        end
        page += 1
      end
    end
  end

  def process_orders
    @processed_orders += (@orders.map do |order|
      {
        'id' => order['id'],
        'date' => Time.parse(order['created_at']['__content__']).to_i,
        'user_id' => order['client']['id'],

        'items' => order['order_lines'].map {|order_line|
          {
            'id' => order_line['product_id'],
            'price' => order_line['sale_price'],
            'category_uniqid' => @categories_cache[order_line['product_id'].to_i],
            'is_available' => true,
            'amount' => order_line['quantity']
          }
        }
      }
    end.select do |order|
      order['user_id'].present? && order['items'].present? && order['items'].any?
    end)
  end

  def send_orders
    if @processed_orders.any?
      @processed_orders.each_slice(100) do |batch|
        body = {
          'shop_id'     => @shop.uniqid,
          'shop_secret' => @shop.secret,
          'orders' => batch,
          'errors_to' => 'anton.zhavoronkov@mkechinov.ru'
        };

        resp = HTTParty.post('http://api.rees46.com/import/orders',
            body: body.to_json,
            headers: { 'Content-Type' => 'application/json' }
        );
      end
    end
  end
end