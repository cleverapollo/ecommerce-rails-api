Shop.find_each do |shop|
  shop.group_1_count.set(shop.shops_users.where(ab_testing_group: 1).count)
  shop.group_2_count.set(shop.shops_users.where(ab_testing_group: 2).count)
end
