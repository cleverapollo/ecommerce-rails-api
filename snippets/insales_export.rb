resp['orders'].map do |order|
  {
    'id' => order['id'],
    'date' => Time.parse(order['created_at']['__content__']).to_i,
    'user_id' => order['client']['id'],

    'items' => order['order_lines'].map {|order_line|
      {
        'id' => order_line['product_id'],
        'price' => order_line['sale_price'],
        'category_id' => nil,
        'is_available' => true,
        'amount' => order_line['quantity']
      }
    }
  }
end
