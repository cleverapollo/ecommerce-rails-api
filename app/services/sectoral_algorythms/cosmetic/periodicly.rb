##
# Расчет размера пользователя
#
module SectoralAlgorythms
  module Cosmetic
    class Periodicly < SectoralAlgorythms::Base

      #период без уточнения
      FIRST_PURCHASE_PERIOD = 4 * 7 * 24 * 3600

      PART_TYPES=['hair', 'face', 'body', 'intim', 'hand', 'leg']

      def initialize(user)
        super
        @periodicly = user.periodicly
      end

      def value
        { 'm' => @physiology['m'], 'f' => @physiology['f'] }
      end

      def trigger_view(item)
        # Периодичность не реагирует на просмотры
      end

      def trigger_purchase(item)
        if item.periodic
          # сохраняем периодичность
          refresh_periodicly(item)
        end

      end

      def refresh_periodicly(item)
        @periodicly['history'] ||= {}
        if @periodicly['history'][item.id].present?
          # Добавляем покупку
          @periodicly['history'][item.id].push(Time.now.to_i)
        else
          @periodicly['history'][item.id]=[Time.now.to_i]
        end
      end


      def recalculate

        periodicly_history = @periodicly['history']
        return if periodicly_history.nil? || periodicly_history.empty?

        @periodicly['calc_periods'] ||= {}
        periodicly_history.each do |item_id, purchase_times|
          # Более 1 покупки, рассчитываем среднее
          if purchase_times.size > 1
            purchase_times = purchase_times.sort
            periods = []
            prev_purchase_time = purchase_times.first
            purchase_times.drop(1).each do |time|
              periods << (time - prev_purchase_time)
              prev_purchase_time = time
            end
            calc_period = periods.map(&:to_i).reduce(:+) / periods.size
            @periodicly['calc_periods'][item_id] = calc_period
          else
            # Считаем период по умолчанию
            @periodicly['calc_periods'][item_id] = FIRST_PURCHASE_PERIOD
          end
        end

      end

      def merge(slave)
        return unless @periodicly && @periodicly['history'].present?
        if slave.periodicly['history'].present?
          slave_history = slave.periodicly['history']
          master_history = @periodicly['history']
          @periodicly['history'] = slave_history.merge(master_history) do |_, periodicly_slave_value, periodicly_master_value|
            (periodicly_slave_value+periodicly_master_value).sort.uniq
          end
        end
      end

      def attributes_for_update
        { :periodicly => @periodicly }
      end

      private

      def default_history
        { 'views' => 0, 'purchase' => 0 }
      end
    end
  end
end
