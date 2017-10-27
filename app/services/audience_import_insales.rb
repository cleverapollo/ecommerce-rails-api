class AudienceImportInsales

  APP_LOGIN = 'rees46'
  APP_SECRET = 'c940a1b06136d578d88999c459083b78'

  def import_audience
    InsalesShop.where('shop_id is not null').each do |i_s|
      shop = Shop.find(i_s.shop_id)
      if shop.connected?
        import_shop_audience(shop.id)
      end
    end
  end

  def import_shop_audience(shop_id)
    shop = Shop.find(shop_id)

    if shop.insales_shop.blank?
      raise 'Это не InSales-магазин'
    end

    @shop = shop
    @insales_shop = shop.insales_shop
    @url = "http://#{@insales_shop.insales_shop}"
    @auth = { username: APP_LOGIN, password: Digest::MD5.hexdigest(@insales_shop.token + APP_SECRET) }
    @processed_users = []

    page = 1; per_page = 25
    loop do
      resp = HTTParty.get(
        "#{@url}/admin/orders.xml?per_page=#{per_page}&page=#{page}",
        basic_auth: @auth,
        headers: {
          'Content-Type' => 'application/xml',
          'User-Agent' => 'REES46 Fetcher 1.0'
        }
      )

      @users = resp['orders']

      if @users.blank? || @users.none?
        break;
      else
        process_orders
        page += 1
      end
    end

    save_audience
  end


  def process_orders
    @processed_users += (@users.map do |user|
      {
        'user_id' => user['client']['id'],
        'user_email' => user['client']['email'],
      }
    end)
  end

  def save_audience
    if @processed_users.any?

      @processed_users.each do |a|
        id = a['user_id'].to_s
        email = a['user_email']
        next if id.blank? || email.blank?

        s_u = @shop.clients.find_by(external_id: id)
        if s_u.blank?
          s_u = @shop.clients.build(external_id: id, user: User.create)
        end

        s_u.email = email || s_u.email

        s_u.save!
      end
    end
  end

end
