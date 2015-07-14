namespace :products do

  desc 'Expire carts'
  task :expire_carts => :environment do
    CartsExpirer.perform
  end


  desc 'Disable expired products'
  task :disable_expired_products => :environment do
    Item.disable_expired
  end


end
