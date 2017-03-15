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

      # @return [Shop]
      attr_accessor :shop

      def initialize(shop)
        @shop = shop
      end

      def perform

        # find calculation segments
        segment_a = Segment.find_calculated_segment(shop, 'A')
        segment_b = Segment.find_calculated_segment(shop, 'B')
        segment_c = Segment.find_calculated_segment(shop, 'C')
        segments = [segment_a, segment_b, segment_c]

        users = {}
        Rails.logger.warn "Collect orders: #{shop.id}"
        Order.where(shop_id: @shop.id).where('date >= ?', 6.months.ago).pluck(:user_id, :value).each do |order|
          users[order[0]] = 0 unless users.key?(order[0])
          users[order[0]] += order[1]
        end
        Rails.logger.warn 'Orders collected'
        data = users.map { |k, v| { user_id: k, sum: users[k].to_i } }.collect.sort { |a,b| a[:sum] <=> b[:sum] }.reverse
        Rails.logger.warn 'Orders sorted'
        result = {a: [], b: [], c: []}
        Rails.logger.warn 'Calculate A'
        index_a = (data.length * 0.15).ceil
        if index_a > 0
          result[:a] = data[0..(index_a-1)]
        end
        if index_a < data.length
          Rails.logger.warn 'Calculate B'
          index_b = index_a + (data.length * 0.35).ceil
          if index_b > index_a
            result[:b] = data[index_a..(index_b-1)]
            Rails.logger.warn 'Calculate C'
            result[:c] = data[index_b..data.length]
          end
        end
        Rails.logger.warn 'All calculated. Nullify all'

        # Удалеям расчетные сегменты у клиентов
        t = Benchmark.ms do
          shop.clients.with_segments(segments.map{|s| s.id}).where.not(user_id: data.map { |x| x[:user_id] } ).update_all(
              "segment_ids = CASE COALESCE(array_length(segment_ids - ARRAY[#{segments.map{|s| s.id}.join(',')}], 1), 0)
                WHEN 0 THEN NULL
                ELSE (segment_ids - ARRAY[#{segments.map{|s| s.id}.join(',')}]) END"
          )
        end
        Rails.logger.warn "Done: #{t.round(2)} ms"

        # Обновляем данные сегмента
        segments.each do |segment|
          Rails.logger.warn "Saving #{segment.name}"
          t = Benchmark.ms { shop.clients.where(user_id: result[segment.name.downcase.to_sym].map { |x| x[:user_id] } ).update_all("segment_ids = array_append(segment_ids, #{segment.id})") }.round(2)
          Rails.logger.warn "Done: #{t} ms"

          # Обновляем статистику сегмента
          Rails.logger.warn "Updating statistic #{segment.name}"
          t = Benchmark.ms do
            segment.update({
                client_count: result[segment.name.downcase.to_sym].count,
                with_email_count: shop.clients.with_segment(segment.id).with_email.count,
                trigger_client_count: shop.clients.with_segment(segment.id).where(triggers_enabled: true).count,
                digest_client_count: shop.clients.with_segment(segment.id).where(digests_enabled: true).count,
                web_push_client_count: shop.clients.with_segment(segment.id).where(web_push_enabled: true).count,
            })
          end
          Rails.logger.warn "Done: #{t.round(2)} ms"
        end

        update_params = {
            overall: shop.clients.count,
            activity_a: result[:a].count,
            activity_b: result[:b].count,
            activity_c: result[:c].count,
            recalculated_at: Date.current,
            digests_overall: shop.clients.with_email.where('digests_enabled IS TRUE').count,
            digests_activity_a: segment_a.digest_client_count,
            digests_activity_b: segment_b.digest_client_count,
            digests_activity_c: segment_c.digest_client_count,
            triggers_overall: shop.clients.with_email.where('triggers_enabled IS TRUE').count,
            triggers_activity_a: segment_a.trigger_client_count,
            triggers_activity_b: segment_b.trigger_client_count,
            triggers_activity_c: segment_c.trigger_client_count,
            with_email: shop.clients.with_email.count,
            with_email_activity_a: segment_a.with_email_count,
            with_email_activity_b: segment_b.with_email_count,
            with_email_activity_c: segment_c.with_email_count,
            web_push_overall: shop.clients.where('web_push_enabled IS TRUE').count,
            web_push_activity_a: segment_a.web_push_client_count,
            web_push_activity_b: segment_b.web_push_client_count,
            web_push_activity_c: segment_c.web_push_client_count,
        }

        AudienceSegmentStatistic.fetch(shop).update! update_params

        true

      end


    end
  end
end
