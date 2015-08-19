module Experimentor
  module Experiments
    class ItemBasedExperiment < Experiments::Base
      def populate
        clear_all
        local_shop = Shop.find_by(name: 'Megashop')
        unless local_shop
          local_shop = create(:shop, id: 670)
        end

        100.times do |i|
          create(:user)
        end

        100.times do |i|
          create(:item, shop: local_shop, sales_rate: rand(100..200), categories: "{1}", brand: 'datakam')
        end

        100.times do |i|
          create(:item, shop: local_shop, sales_rate: rand(100..200), categories: "{2}", brand: 'datakam')
        end

        ItemCategory.create!(shop_id: local_shop.id, name: "Видеорегисраторы", external_id: '1')
        ItemCategory.create!(shop_id: local_shop.id, name: 'Все остальное', external_id: '2')

        10.times do |i|
          ap "create action #{i}"
          create_action(local_shop, user[i], item[i])
          create_action(local_shop, user[i], item[i*2])
          create_action(local_shop, user[i], item[i*3])
          create_action(local_shop, user[i], item[i*4])

          create_action(local_shop, user[i*2], item[i*3])
          create_action(local_shop, user[i*2], item[i*2])
          create_action(local_shop, user[i*2], item[i*4], 'purchase', nil)
          create_action(local_shop, user[i*2], item[i*6])

          create_action(local_shop, user[i*3], item[i*2])
          create_action(local_shop, user[i*3], item[i*4])
          create_action(local_shop, user[i*3], item[i*7], 'purchase', nil)
          create_action(local_shop, user[i*3], item[i*8])

          create_action(local_shop, user[i*3], item[i])
          create_action(local_shop, user[i*3], item[i*3])
          create_action(local_shop, user[i*3], item[i*9], 'purchase', nil)
          create_action(local_shop, user[i*3], item[i*6], 'cart', nil)

          create_action(local_shop, user[i*4], item[i*6])
          create_action(local_shop, user[i*4], item[i*5], 'purchase', nil)
          create_action(local_shop, user[i*4], item[i], 'cart', nil)
          create_action(local_shop, user[i*4], item[i*2])
        end


      end

      def iterate(iteration_params)
        ap User.first.id
        ap User.last.id

        mahout_service = MahoutService.new
        mahout_service.open
        mahout_service.relink_user(User.first.id, User.last.id)
        mahout_service.close
        # recommender = Recommender::Impl::Experiment.new(iteration_params)
        # ap recommender.recommendations
      end
    end
  end
end
