module People
  module Segmentation
    class ActivityWorker

      # @return [Segment]
      attr_accessor :segment_a, :segment_b, :segment_c

      class << self
        def perform_all
          Shop.active.connected.each do |shop|
            self.new(shop).perform
          end
          Shop.active.connected.each do |shop|
            self.new(shop).update.update_overall
          end
        end
      end

      # @return [Shop]
      attr_accessor :shop

      def initialize(shop)
        @shop = shop
      end

      # Расчеты сегментов для пользователей
      # @return [People::Segmentation::ActivityWorker]
      def perform

        # Находит сегменты магазина
        segments = fetch_shop_segments

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
          other_segments = segments.map {|s| s.id} - [segment.id]
          t = Benchmark.ms { shop.clients.where(user_id: result[segment.name.downcase.to_sym].map { |x| x[:user_id] } ).update_all("segment_ids = array_append(segment_ids, #{segment.id}) - ARRAY[#{other_segments.join(',')}]") }.round(2)
          Rails.logger.warn "Done: #{t} ms"
        end

        self

      end

      # Обновление статистики после расчетов
      # @return [People::Segmentation::ActivityWorker]
      def update
        Rails.logger.warn "Updating: #{shop.id}"

        # Находит сегменты магазина
        segments = fetch_shop_segments

        segments.each do |segment|
          # Обновляем статистику сегмента
          Rails.logger.warn "Updating statistic #{segment.name}"
          Rails.logger.warn "Done: #{Benchmark.ms { People::Segmentation::SegmentWorker.new.perform(segment) }.round(2)} ms"
        end

        # Ищем ранее сохраненную статистику
        statistic = AudienceSegmentStatistic.fetch(shop)

        Rails.logger.warn ' * Updating AudienceSegmentStatistic'
        update_params = {
            activity_a: segment_a.client_count,
            activity_b: segment_b.client_count,
            activity_c: segment_c.client_count,
            recalculated_at: Date.current,
            digests_activity_a: segment_a.digest_client_count,
            digests_activity_b: segment_b.digest_client_count,
            digests_activity_c: segment_c.digest_client_count,
            triggers_activity_a: segment_a.trigger_client_count,
            triggers_activity_b: segment_b.trigger_client_count,
            triggers_activity_c: segment_c.trigger_client_count,
            with_email_activity_a: segment_a.with_email_count,
            with_email_activity_b: segment_b.with_email_count,
            with_email_activity_c: segment_c.with_email_count,
            web_push_activity_a: segment_a.web_push_client_count,
            web_push_activity_b: segment_b.web_push_client_count,
            web_push_activity_c: segment_c.web_push_client_count,
        }
        statistic.update! update_params

        self
      end

      # Обновляет глобальную статистику
      # @return [People::Segmentation::ActivityWorker]
      def update_overall

        # Ищем ранее сохраненную статистику
        statistic = AudienceSegmentStatistic.fetch(shop)
        update_params = {
            recalculated_at: Date.current,
        }

        Rails.logger.warn "   - overall: #{Benchmark.ms { update_params[:overall] = shop.clients.count }.round(2)} ms"
        Rails.logger.warn "   - digests_overall: #{Benchmark.ms { update_params[:digests_overall] = shop.clients.with_email.where('digests_enabled IS TRUE').count }.round(2)} ms"
        Rails.logger.warn "   - triggers_overall: #{Benchmark.ms { update_params[:triggers_overall] = shop.clients.with_email.where('triggers_enabled IS TRUE').count }.round(2)} ms"
        Rails.logger.warn "   - with_email: #{Benchmark.ms { update_params[:with_email] = shop.clients.with_email.count }.round(2)} ms"
        Rails.logger.warn "   - web_push_overall: #{Benchmark.ms { update_params[:web_push_overall] = shop.clients.where('web_push_enabled IS TRUE').count }.round(2)} ms"

        statistic.update! update_params

        self
      end

      private

      # @return [Array<Segment>]
      def fetch_shop_segments
        # find calculation segments
        self.segment_a = Segment.find_calculated_segment(shop, 'A')
        self.segment_b = Segment.find_calculated_segment(shop, 'B')
        self.segment_c = Segment.find_calculated_segment(shop, 'C')

        [self.segment_a, self.segment_b, self.segment_c]
      end

    end
  end
end
