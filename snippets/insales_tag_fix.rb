shop = Shop.find(228)
insales_shop = shop.insales_shop

app_login = 'rees46'
app_secret = 'c940a1b06136d578d88999c459083b78'

id = 7873

url = "http://#{insales_shop.insales_shop}/admin/js_tags.xml"

auth = { username: app_login, password: Digest::MD5.hexdigest(insales_shop.token + app_secret) }

tag = "(function() { var fileref = document.createElement('script'); fileref.setAttribute('type','text/javascript'); fileref.setAttribute('src', '//cdn.rees46.com/rees_insales.min.2.js'); fileref.setAttribute('async', 'true'); document.getElementsByTagName('head')[0].appendChild(fileref); })();"

tag3 = '<js-tag><type type="string">JsTag::TextTag</type><content>' + tag + '</content></js-tag>'

resp = HTTParty.post(url, body: tag3, basic_auth: auth, headers: { 'Content-Type' => 'application/xml' })

