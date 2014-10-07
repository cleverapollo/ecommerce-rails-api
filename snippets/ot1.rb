shop = Shop.find(289);
stats = {};

File.open('onlinetours.csv', 'w') do |file|
  shop.user_shop_relations.includes(:user).find_each do |u_s_r|
    begin
      recommender = Recommender::Impl::Interesting.new(OpenStruct.new(
        shop: shop,
        user: u_s_r.user,
        limit: 10
      ));

      recommended_ids = recommender.recommended_ids;
      recommended_ids = shop.items.available.where(id: recommended_ids).pluck(:id);
      recommended_ids_external = shop.items.available.where(id: recommended_ids).pluck(:uniqid);
      recommended_ids_count = recommended_ids_external.count;

      str = [u_s_r.user_id, u_s_r.uniqid, recommended_ids_count, recommended_ids.join(';'), recommended_ids_external.join(';')].join(',')
      puts str
      file.puts(str)
      stats[recommended_ids.count] ||= 0
      stats[recommended_ids.count] += 1
    rescue Exception => e
      puts e
      retry
    end
  end
end

puts stats
