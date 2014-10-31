shop = Shop.find(289);
stats = {};

tunnel = BrB::Tunnel.create(nil, 'brb://localhost:5555')

available_ids = []; item_ids_map = {}
shop.items.available.find_each do |item|
  available_ids << item.id
  item_ids_map[item.id] = item.uniqid
end

File.open('onlinetours.csv', 'w') do |file|
  shop.user_shop_relations.includes(:user).find_each do |u_s_r|
    user_id = u_s_r.user_id; shop_id = shop.id;
    preferences = MahoutPreferences.new(user_id, shop_id, nil).fetch
    options = {
      limit: 10,
      include: available_ids,
      exclude: [],
      preferences: preferences
    };
    recommended_ids = []
    begin
      recommended_ids = []
      Timeout::timeout(2) {
        if preferences.any?
          recommended_ids = tunnel.user_based_block(shop.id, options)
        end
      }
      recommended_ids = [] if recommended_ids.nil?
    rescue Timeout::Error => e
      puts "#{e.class} #{e.message}"
      recommended_ids = []
    end
    recommended_ids_external = recommended_ids.map{|r_id| item_ids_map[r_id] }
    recommended_ids_count = recommended_ids_external.count
    if recommended_ids_count == 0
      puts 'Fake'
      a = shop.actions.where(user_id: user_id).order('timestamp DESC').first

      i = a.try(:item)
      if i.present? && i.locations[0].present?
        # Найти живые товары для города юзера
        items = shop.items.available.in_locations(i.locations)

        # Выбрать из них 3-10
        recommended_ids = items.order('RANDOM()').last(rand(8) + 3).map(&:id)

        recommended_ids_external = recommended_ids.map{|r_id| item_ids_map[r_id] }
        recommended_ids_count = recommended_ids_external.count
      end
    else
      puts 'Real'
    end
    str = [u_s_r.user_id, u_s_r.uniqid, recommended_ids_count, recommended_ids.join(';'), recommended_ids_external.join(';')].join(',')
    puts str
    file.puts(str)
    stats[recommended_ids.count] ||= 0
    stats[recommended_ids.count] += 1
  end
end

puts stats
