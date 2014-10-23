shop = Shop.find(114);

available_ids = shop.items.where(uniqid: HTTParty.get('http://my.timepad.ru/api/events?fields=id&count=50000').map{|r| r['id'].to_s }).pluck(:id);

tunnel = BrB::Tunnel.create(nil, 'brb://localhost:5555');

total_time = 0.0;
measurments_count = 0.0;
File.open('/home/rails/timepad_recommendations.csv', 'w') do |file|
  shop.user_shop_relations.with_email.find_each do |u_s_r|
    b = Benchmark.measure {
      options = {
        #preferences: MahoutPreferences.new(u_s_r.user_id, shop.id, nil).fetch,
        preferences: [1, 2, 3],
        #include: available_ids,
        include: [],
        exclude: [],
        limit: 5
      }

      puts "#{u_s_r.email} #{tunnel.user_based_block(nil, options)}"
    }

    total_time = total_time + b.real;
    measurments_count += 1;
    puts total_time.to_f/measurments_count.to_f
  end
end
