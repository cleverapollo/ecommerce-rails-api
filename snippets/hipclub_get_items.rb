auth = { username: 'hipway', password: 'hip_pass' }
json = HTTParty.get('http://hipway.ru/json/travels', basic_auth: auth)
json = JSON.parse(json)


j.each do |j_item|
  i = Item.find_by(uniqid: "travel#{j_item['id'].to_s}")
  i.update(image_url: j_item['image_url'], price: j_item['price'].to_f, url: j_item['url'], name: j_item['name'])
end