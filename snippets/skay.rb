orders = {}

File.open('/Users/anton-zh/Downloads/orders_general_10162014.csv', 'r').each_line do |line|
  line = line.gsub('"', '').gsub("\n", '')
  order_id, _, user_id = line.split(';')
  orders[order_id] = {
    user_id: user_id,
    items: []
  }
end

File.open('/Users/anton-zh/Downloads/order_items_general_10162014.csv', 'r').each_line do |line|
  line = line.gsub('"', '').gsub("\n", '')
  order_id, _1, item_id, _2, price, amount, _3 = line.split(';')

  if orders[order_id].present?
    orders[order_id][:items] << {
      'id' => item_id,
      'price' => price.to_f,
      'amount' => amount.to_i
    }
  end
end

orders = orders.map do |k, v|
  {
    'id' => k.to_s,
    'user_id' => v[:user_id],
    'items' => v[:items]
  }
end;

orders.each_slice(100) do |slice|
  body = {
    'shop_id' => 'b2b6fb333bd2505192efec4eeff7f3',
    'shop_secret' => '3376b06170c0a0c503a84dac13a1b082',
    'orders' => slice
  }

  resp = HTTParty.post('http://api.rees46.com/import/orders',
    body: body.to_json,
    headers: { 'Content-Type' => 'application/json' }
  );
  return;
end
