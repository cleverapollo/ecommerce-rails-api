shop = Shop.find(245);
insales_shop = InsalesShop.find_by(shop_id: 245);

app_login = 'rees46';
app_secret = 'c940a1b06136d578d88999c459083b78';

url = "http://#{insales_shop.insales_shop}";
auth = { username: app_login, password: Digest::MD5.hexdigest(insales_shop.token + app_secret) };

page = 1; per_page = 250;
loop do
  resp = HTTParty.get("#{url}/admin/products.xml?per_page=#{per_page}&page=#{page}", 
                      basic_auth: auth, 
                      headers: { 'Content-Type' => 'application/xml' });

  items = resp['products'];

  if items.blank? || items.none?
    break
  else
    items.each do |item|
      uniqid = item['id'].to_s;
      category = item['canonical_url_collection_id'].to_s;

      item = shop.items.find_by(uniqid: uniqid);

      if item.present?
        puts "Item found #{item}";
        puts 'updating';
        puts "#{{ category_uniqid: category, categories: [category] }}";
        item.update(category_uniqid: category, categories: [category])
        shop.actions.where(item_id: item.id).update_all(category_uniqid: category, categories: "{#{category}}")
      end
    end
    page += 1
  end
end