namespace :populate do

  desc 'Clear data after populate'
  task :clear do
    ap "Clearing"
    PopulateHelper.clear_all
  end

  desc 'Create mahout actions'
  task :action => :clear do
    ap "Populate actions"
    require 'factory_girl_rails'
    shop = Shop.find_by(name: "Megashop")
    shop ||= FactoryGirl.create(:shop)

    users = []
    10.times do |i|
      users.push(FactoryGirl.create(:user))
    end

    items = []
    10.times do |i|
      items.push(FactoryGirl.create(:item, shop: shop, sales_rate: rand(100..200), categories: "{1}"))
    end

    PopulateHelper.create_action(shop, users[0], items[0], true)
    PopulateHelper.create_action(shop, users[0], items[1], true)
    PopulateHelper.create_action(shop, users[0], items[2], true)

    PopulateHelper.create_action(shop, users[1], items[3], true)
    PopulateHelper.create_action(shop, users[1], items[4], true)
    PopulateHelper.create_action(shop, users[1], items[2], true)

    PopulateHelper.create_action(shop, users[2], items[1], true)
    PopulateHelper.create_action(shop, users[2], items[0], true)
    PopulateHelper.create_action(shop, users[2], items[4], true)

    PopulateHelper.create_action(shop, users[3], items[3], true)
    PopulateHelper.create_action(shop, users[3], items[4], true)
    PopulateHelper.create_action(shop, users[3], items[0], true)

    PopulateHelper.create_action(shop, users[4], items[2], true)
    PopulateHelper.create_action(shop, users[4], items[3], true)
    PopulateHelper.create_action(shop, users[4], items[4], true)

  end

end

