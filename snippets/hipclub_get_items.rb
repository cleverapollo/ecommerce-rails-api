auth = { username: 'hipway', password: '#HipWaY7*' }
json = HTTParty.get('http://hipway.ru/json/travels', basic_auth: auth)
json = json.parsed_response

ids = []

json.each do |j_item|
  id = "travel#{j_item['id'].to_s}"
  i = Item.find_by!(uniqid: id)
  ids << id
  i.update(image_url: j_item['image_url'], price: j_item['price'].to_f, url: j_item['url'], name: j_item['name'])
end