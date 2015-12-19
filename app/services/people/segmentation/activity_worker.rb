module People
  module Segmentation
    class ActivityWorker

      class << self
        def perform_all
          Shop.active.connected.each do |shop|
            self.new(shop).perform
          end
        end
      end

      attr_accessor :shop

      def initialize(shop)
        @shop = shop
      end

      def perform
        users = {}
        Order.where(shop_id: @shop.id).where('date >= ?', 6.months.ago).lazy.each do |order|
          users[order.user_id] = 0 unless users.key?(order.user_id)
          users[order.user_id] += order.value
        end
        data = users.map { |k, v| { user_id: k, sum: users[k].to_i } }.collect.sort { |a,b| a[:sum] <=> b[:sum] }.reverse
        result = {a: [], b: [], c: []}
        index_a = (data.length * 0.15).ceil
        if index_a > 0
          result[:a] = data[0..(index_a-1)]
        end
        if index_a < data.length
          index_b = index_a + (data.length * 0.35).ceil
          if index_b > index_a
            result[:b] = data[index_a..(index_b-1)]
            result[:c] = data[index_b..data.length]
          end
        end

        @shop.clients.where.not(id: data.map { |x| x[:user_id] } ).update_all activity_segment: nil
        @shop.clients.where(user_id: result[:a].map { |x| x[:user_id] } ).update_all activity_segment: People::Segmentation::Activity::A
        @shop.clients.where(user_id: result[:b].map { |x| x[:user_id] } ).update_all activity_segment: People::Segmentation::Activity::B
        @shop.clients.where(user_id: result[:c].map { |x| x[:user_id] } ).update_all activity_segment: People::Segmentation::Activity::C

        true

      end


    end
  end
end
