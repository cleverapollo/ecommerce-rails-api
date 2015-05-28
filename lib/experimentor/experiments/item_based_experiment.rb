module Experimentor
  module Experiments
    class ItemBasedExperiment < Experiments::Base
      def populate
        clear_all
        local_shop = create(:shop)

        10.times do |i|
          create(:user)
        end

        10.times do |i|
          create(:item, shop: local_shop, sales_rate: rand(100..200), categories: "{1}")
        end

        create_action(local_shop, user[0], item[0])
        create_action(local_shop, user[0], item[1])
        create_action(local_shop, user[0], item[2], 'purchase')
        create_action(local_shop, user[0], item[3])

        create_action(local_shop, user[1], item[2])
        create_action(local_shop, user[1], item[3])
        create_action(local_shop, user[1], item[4])
        create_action(local_shop, user[1], item[5])

        create_action(local_shop, user[2], item[1])
        create_action(local_shop, user[2], item[3])
        create_action(local_shop, user[2], item[6])
        create_action(local_shop, user[2], item[7])

        create_action(local_shop, user[3], item[0])
        create_action(local_shop, user[3], item[2])
        create_action(local_shop, user[3], item[8])
        create_action(local_shop, user[3], item[9])

        create_action(local_shop, user[4], item[5])
        create_action(local_shop, user[4], item[4])
        create_action(local_shop, user[4], item[0])
        create_action(local_shop, user[4], item[1])

      end

      def iterate(iteration_params)
        recommender = Recommender::Impl::Popular.new(iteration_params)
        ap recommender.recommendations
      end
    end
  end
end
