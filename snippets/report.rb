RECOMMENDERS = ['interesting', 'similar', 'see_also', 'also_bought', 'buying_now', 'popular', 'recently_viewed', 'rescore', 'trigger_mail'];
#SHOP_IDS = [1 ,281 ,401 ,374 ,188 ,100 ,250 ,194 ,356 ,349 ,400 ,408 ,292 ,303 ,263 ,306 ,151 ,371]
SHOP_IDS = [306]
DATE_START = Date.new(2014, 9, 23);
DATE_END = Date.new(2014, 10, 9)

def percents(a, b)
  "#{((a > 0 ? (a.to_f / b) : 0) * 100).round(2)}%"
end

Shop.where(id: SHOP_IDS).map do |shop|
  puts "<h1>Статистика для #{shop.name}</h1>"

  interactions_scope = Interaction.where(shop_id: shop.id).where('created_at >= ? AND created_at <= ?', DATE_START, DATE_END).where(code: 1);
  total_views = interactions_scope.count;
  puts "<h3>Всего просмотров: #{total_views}</h3>"

  ordered_items_scope = OrderItem.joins(:order).where('orders.shop_id = ?', shop.id).where('orders.date >= ? AND orders.date <= ?', DATE_START, DATE_END);
  total_ordered_items_count = ordered_items_scope.count;
  puts "<h3>Всего куплено товаров: #{total_ordered_items_count}</h3>"

  stats = []
  RECOMMENDERS.each do |recommender|
    views_in_recommender = interactions_scope.where(recommender_code: Interaction::RECOMMENDER_CODES[recommender]).count;
    ordered_items_in_recommender = ordered_items_scope.where(recommended_by: recommender).count;

    r = [recommender, views_in_recommender, percents(views_in_recommender, total_views), ordered_items_in_recommender, percents(ordered_items_in_recommender, total_ordered_items_count)]

    if views_in_recommender != 0
      stats << r
    end
  end

  stats = stats.sort{|s1, s2| s1[1] <=> s2[1] }


  puts '<table border="1" cellspacing="0"><tr>'
  puts ['Рекомендер', 'Просмотров', '% РП', 'Куплено товаров', '% КТ'].map{|v| "<td>#{v}</td>"}
  puts "</tr>"
  stats.each do |s|
    puts '<tr>'
    puts s.map{|v| "<td>#{v}</td>"}
    puts '</tr>'
  end
  puts "</table>"

  puts '<hr />'
end && nil

