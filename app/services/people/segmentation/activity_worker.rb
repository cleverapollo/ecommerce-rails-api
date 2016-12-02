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
        Rails.logger.warn "Collect orders"
        Order.where(shop_id: @shop.id).where('date >= ?', 6.months.ago).pluck(:user_id, :value).each do |order|
          users[order[0]] = 0 unless users.key?(order[0])
          users[order[0]] += order[1]
        end
        Rails.logger.warn "Orders collected"
        data = users.map { |k, v| { user_id: k, sum: users[k].to_i } }.collect.sort { |a,b| a[:sum] <=> b[:sum] }.reverse
        Rails.logger.warn "Orders sorted"
        result = {a: [], b: [], c: []}
        Rails.logger.warn "Calculate A"
        index_a = (data.length * 0.15).ceil
        if index_a > 0
          result[:a] = data[0..(index_a-1)]
        end
        if index_a < data.length
          Rails.logger.warn "Calculate B"
          index_b = index_a + (data.length * 0.35).ceil
          if index_b > index_a
            result[:b] = data[index_a..(index_b-1)]
            Rails.logger.warn "Calculate C"
            result[:c] = data[index_b..data.length]
          end
        end
        Rails.logger.warn "All calculated. Nullify all"
        @shop.clients.where.not(user_id: data.map { |x| x[:user_id] } ).where('activity_segment is not null').update_all activity_segment: nil
        Rails.logger.warn "Save A"
        @shop.clients.where(user_id: result[:a].map { |x| x[:user_id] } ).update_all activity_segment: People::Segmentation::Activity::A
        Rails.logger.warn "Save B"
        @shop.clients.where(user_id: result[:b].map { |x| x[:user_id] } ).update_all activity_segment: People::Segmentation::Activity::B
        Rails.logger.warn "Save C"
        @shop.clients.where(user_id: result[:c].map { |x| x[:user_id] } ).update_all activity_segment: People::Segmentation::Activity::C
        Rails.logger.warn "Done"

        result[:digests_overall] = @shop.clients.with_email.where('digests_enabled IS TRUE').count
        result[:digests_activity_a] = @shop.clients.with_email.where('digests_enabled IS TRUE AND activity_segment is not null and activity_segment = ?', People::Segmentation::Activity::A).count
        result[:digests_activity_b] = @shop.clients.with_email.where('digests_enabled IS TRUE AND activity_segment is not null and activity_segment = ?', People::Segmentation::Activity::B).count
        result[:digests_activity_c] = @shop.clients.with_email.where('digests_enabled IS TRUE AND activity_segment is not null and activity_segment = ?', People::Segmentation::Activity::C).count
        result[:triggers_overall] = @shop.clients.with_email.where('triggers_enabled IS TRUE').count
        result[:triggers_activity_a] = @shop.clients.where('triggers_enabled IS TRUE AND activity_segment is not null and activity_segment = ?', People::Segmentation::Activity::A).count
        result[:triggers_activity_b] = @shop.clients.where('triggers_enabled IS TRUE AND activity_segment is not null and activity_segment = ?', People::Segmentation::Activity::B).count
        result[:triggers_activity_c] = @shop.clients.where('triggers_enabled IS TRUE AND activity_segment is not null and activity_segment = ?', People::Segmentation::Activity::C).count
        result[:with_email] = @shop.clients.with_email.count
        result[:with_email_activity_a] = @shop.clients.with_email.where('activity_segment = ?', People::Segmentation::Activity::A).count
        result[:with_email_activity_b] = @shop.clients.with_email.where('activity_segment = ?', People::Segmentation::Activity::B).count
        result[:with_email_activity_c] = @shop.clients.with_email.where('activity_segment = ?', People::Segmentation::Activity::C).count
        result[:web_push_overall] = @shop.clients.where('web_push_enabled IS TRUE').count
        result[:web_push_activity_a] = @shop.clients.where('web_push_enabled IS TRUE AND activity_segment = ?', People::Segmentation::Activity::A).count
        result[:web_push_activity_b] = @shop.clients.where('web_push_enabled IS TRUE AND activity_segment = ?', People::Segmentation::Activity::B).count
        result[:web_push_activity_c] = @shop.clients.where('web_push_enabled IS TRUE AND activity_segment = ?', People::Segmentation::Activity::C).count

        update_params = {
            overall: shop.clients.count,
            activity_a: result[:a].count,
            activity_b: result[:b].count,
            activity_c: result[:c].count,
            recalculated_at: Date.current,
            digests_overall: result[:digests_overall],
            digests_activity_a: result[:digests_activity_a],
            digests_activity_b: result[:digests_activity_b],
            digests_activity_c: result[:digests_activity_c],
            triggers_overall: result[:triggers_overall],
            triggers_activity_a: result[:triggers_activity_a],
            triggers_activity_b: result[:triggers_activity_b],
            triggers_activity_c: result[:triggers_activity_c],
            with_email: result[:with_email],
            with_email_activity_a: result[:with_email_activity_a],
            with_email_activity_b: result[:with_email_activity_b],
            with_email_activity_c: result[:with_email_activity_c],
            web_push_overall: result[:web_push_overall],
            web_push_activity_a: result[:web_push_activity_a],
            web_push_activity_b: result[:web_push_activity_b],
            web_push_activity_c: result[:web_push_activity_c],
        }

        AudienceSegmentStatistic.fetch(@shop).update! update_params

        true

      end


    end
  end
end
