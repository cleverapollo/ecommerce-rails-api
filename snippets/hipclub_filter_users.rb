hipclub_users = Set.new(UserShopRelation.where(shop_id: 134).pluck(:uniqid).to_a)

File.open('/home/rails/hipclib_users_filtered_20140711.csv', 'w') do |file|
  File.open('/home/rails/20140711-users-id-email-auth_token.csv').each_line do |line|
    id, email, key = line.gsub("\n", '').split(',')

    if email.present? && key.present? && hipclub_users.include?(id.to_s)
      file.puts line
    end
  end
end