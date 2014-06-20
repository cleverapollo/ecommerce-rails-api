reload!
ActiveRecord::Base.logger = nil
shop = Shop.find(180)

count = shop.user_shop_relations.count
counter = 0

File.open('snippets/tyres_2.csv', 'w') do |file|
  shop.user_shop_relations.each do |u_s_r|
    system('clear')
    counter += 1
    puts "#{counter} / #{count}"
    user = u_s_r.user

    # Interesting
    i_r = Recommender::Impl::Interesting.new(OpenStruct.new(shop: shop, user: user, limit: 5)).recommended_ids
    i_r_items = Item.where(id: i_r)

    # See also
    s_r_params = OpenStruct.new(shop: shop, user: user, limit: 3, cart_item_ids: user.actions.map(&:item_id))
    s_r = Recommender::Impl::SeeAlso.new(s_r_params).recommended_ids
    s_r_items = Item.where(category_uniqid: 'wheel').where(id: s_r)

    # Repeat
    o = Order.where(user_id: user.id).where('date <= ?', 2.years.ago).first
    o_r = []
    if o.present?
      o_i = o.order_items.first
      if o_i.item.category_uniqid == 'tyres'
        o_r = [o_i.item]
      end
    end

    (i_r_items + s_r_items + o_r).each do |item|
      file.puts([u_s_r.uniqid, item.uniqid].join('|'))
    end
  end
end
