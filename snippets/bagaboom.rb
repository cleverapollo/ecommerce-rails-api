insales_shop = InsalesShop.find_by(insales_id: session[:insales_id])

      url = "http://#{insales_shop.insales_shop}/admin/js_tags.xml"

      tag1 = '<js-tag><type type="string">JsTag::FileTag</type><content>//cdn.rees46.com/rees46_script.js</content></js-tag>'
      tag2 = '<js-tag><type type="string">JsTag::FileTag</type><content>//cdn.rees46.com/rees_insales.min.js</content></js-tag>'
      tag3 = '<js-tag><type type="string">JsTag::TextTag</type><content>window.__rees_shop_id = "' + shop.uniqid + '";</content></js-tag>'

      auth = { username: Insales::APP_LOGIN, password: Digest::MD5.hexdigest(insales_shop.token + Insales::APP_SECRET) }

      [tag1, tag2, tag3].each do |tag|
        resp = HTTParty.post(url, body: tag, basic_auth: auth, headers: { 'Content-Type' => 'application/xml' })
      end

      insales_shop.update(shop: shop)

      session.delete(:insales_id)
      session.delete(:insales_shop)



insales_shop = InsalesShop.find(23)
shop = Shop.find(168)
url = "http://#{insales_shop.insales_shop}/admin/js_tags.xml"
tag1 = '<js-tag><type type="string">JsTag::FileTag</type><content>//cdn.rees46.com/rees46_script.js</content></js-tag>'
tag2 = '<js-tag><type type="string">JsTag::FileTag</type><content>//cdn.rees46.com/rees_insales.min.js</content></js-tag>'
tag3 = '<js-tag><type type="string">JsTag::TextTag</type><content>window.__rees_shop_id = "' + shop.uniqid + '";</content></js-tag>'
auth = { username: Insales::APP_LOGIN, password: Digest::MD5.hexdigest(insales_shop.token + Insales::APP_SECRET) }
[tag1, tag2, tag3].each do |tag|
  resp = HTTParty.post(url, body: tag1, basic_auth: auth, headers: { 'Content-Type' => 'application/xml' })
end
insales_shop.update(shop: shop)


resp = HTTParty.post(url, body: tag1, basic_auth: auth, headers: { 'Content-Type' => 'application/xml' })