namespace :fix do

  desc 'Relink user emails'
  task :relink_email => :environment do
    puts "Relink emails"
    Client.select('email, shop_id').where.not(email:nil).having('count(email) > 1').group(:email, :shop_id).each do |client|
      puts "Linking #{client.email} in #{client.shop_id}"
      clients_with_current_mail = Client.where(email: client.email, shop_id:client.shop_id).order(id: :asc)
      if clients_with_current_mail.size>1
        oldest_user = clients_with_current_mail.first.user
        clients_with_current_mail.each { |merge_client| UserMerger.merge(oldest_user, merge_client.user) unless merge_client.user.id==oldest_user.id }
      end
    end
  end

end

