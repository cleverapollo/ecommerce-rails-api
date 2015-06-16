module Experimentor
  module Experiments
    class ItemBasedExperiment < Experiments::Base
      def populate
        clear_all
        local_shop = create(:shop)

        100.times do |i|
          create(:user)
        end

        100.times do |i|
          create(:item, shop: local_shop, sales_rate: rand(100..200), categories: "{1}", brand:'datakam')
        end

        100.times do |i|
          create(:item, shop: local_shop, sales_rate: rand(100..200), categories: "{2}", brand:'datakam')
        end

        ItemCategory.create!(shop_id:local_shop.id, name:"Видеорегисраторы", external_id:'1')
        ItemCategory.create!(shop_id:local_shop.id,name:'Все остальное', external_id:'2')

        10.times do |i|
          create_action(local_shop, user[i], item[i])
          create_action(local_shop, user[i], item[i*2])
          create_action(local_shop, user[i], item[i*3], 'purchase', nil)
          create_action(local_shop, user[i], item[i*4])

          create_action(local_shop, user[i*2], item[i*3])
          create_action(local_shop, user[i*2], item[i*2])
          create_action(local_shop, user[i*2], item[i*4], 'purchase', nil)
          create_action(local_shop, user[i*2], item[i*6])

          create_action(local_shop, user[i*3], item[i*2])
          create_action(local_shop, user[i*3], item[i*4])
          create_action(local_shop, user[i*3], item[i*7])
          create_action(local_shop, user[i*3], item[i*8])

          create_action(local_shop, user[i*3], item[i])
          create_action(local_shop, user[i*3], item[i*3])
          create_action(local_shop, user[i*3], item[i*9])
          create_action(local_shop, user[i*3], item[i*6])

          create_action(local_shop, user[i*4], item[i*6])
          create_action(local_shop, user[i*4], item[i*5])
          create_action(local_shop, user[i*4], item[i])
          create_action(local_shop, user[i*4], item[i*2])
        end


      end

      def iterate(iteration_params)
        recommender = Recommender::Impl::Experiment.new(iteration_params)
        ap recommender.recommended_ids
        ap recommender.recommendations
      end
    end
  end
end
