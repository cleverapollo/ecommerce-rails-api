# {
#     :weighted => {
#         5 => 2.762160062789917,
#         6 => 2.762160062789917,
#         7 => 0.6713992357254028,
#         8 => 0.6713992357254028,
#         9 => 0.6713992357254028,
#         10 => 0.6713992357254028
#     }
# }

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

        create_action(local_shop, user[0], item[0], true)
        create_action(local_shop, user[0], item[1], true)
        create_action(local_shop, user[0], item[2], true)
        create_action(local_shop, user[0], item[3], true)

        create_action(local_shop, user[1], item[2], true)
        create_action(local_shop, user[1], item[3], true)
        create_action(local_shop, user[1], item[4], true)
        create_action(local_shop, user[1], item[5], true)

        create_action(local_shop, user[2], item[1], true)
        create_action(local_shop, user[2], item[3], true)
        create_action(local_shop, user[2], item[6], true)
        create_action(local_shop, user[2], item[7], true)

        create_action(local_shop, user[3], item[0], true)
        create_action(local_shop, user[3], item[2], true)
        create_action(local_shop, user[3], item[8], true)
        create_action(local_shop, user[3], item[9], true)

        create_action(local_shop, user[4], item[5], true)
        create_action(local_shop, user[4], item[4], true)
        create_action(local_shop, user[4], item[0], true)
        create_action(local_shop, user[4], item[1], true)

      end

      def iterate(iteration_params)
        recommender = Recommender::Impl::Experiment.new(iteration_params)
        ap recommender.recommendations
      end
    end
  end
end
