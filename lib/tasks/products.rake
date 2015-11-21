namespace :products do

  desc 'Expire carts'
  task :expire_carts => :environment do
    CartsExpirer.perform
  end

end
