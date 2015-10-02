##
# Расчет размера пользователя
#
module SectoralAlgorythms
  module VirtualProfile
    class Periodicly < SectoralAlgorythms::Base

      #период без уточнения
      FIRST_PURCHASE_PERIOD = 4 * 7 * 24 * 3600

      def initialize(profile)
        super
        @periodicly = @profile.periodicly
      end

      def trigger_view(item)
        # Периодичность не реагирует на просмотры
      end

      def trigger_purchase(item)
        if item.try(:periodic) && item.periodic
          # сохраняем периодичность
          refresh_periodicly(item)
        end

      end

      def refresh_periodicly(item)
        @periodicly[:history] ||= {}
        if @periodicly[:history][item.id].present?
          # Добавляем покупку
          @periodicly[:history][item.id].push(Time.now.to_i)
        else
          @periodicly[:history][item.id]=[Time.now.to_i]
        end
      end


      def recalculate

        periodicly_history = @periodicly[:history]
        return if periodicly_history.nil? || periodicly_history.empty?

        @periodicly[:calc_periods] ||= {}
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
            @periodicly[:calc_periods][item_id] = calc_period
          else
            # Считаем период по умолчанию
            @periodicly[:calc_periods][item_id] = FIRST_PURCHASE_PERIOD
          end
        end


        # Ближайший триггер выносим наверх
        times = []
        items = []

        item_times_buy = {}

        @periodicly[:history].each do |item_id, purchase_times|
          last_purchase_time = purchase_times.last
          time_to_buy = last_purchase_time+@periodicly[:calc_periods][item_id]
          times << time_to_buy
          items << item_id
          item_times_buy[item_id]=time_to_buy
        end
        @periodicly[:item_times_to_buy]=item_times_buy

        next_trigger_time = times.each_with_index.min
        @periodicly[:next_trigger] = next_trigger_time.first
        @periodicly[:next_item] = items[next_trigger_time.last]


      end

      def merge(slave)
        return unless @periodicly && @periodicly[:history].present?
        if slave.periodicly[:history].present?
          slave_history = slave.periodicly[:history]
          master_history = @periodicly[:history]
          @periodicly[:history] = slave_history.merge(master_history) do |_, periodicly_slave_value, periodicly_master_value|
            (periodicly_slave_value+periodicly_master_value).sort.uniq
          end
        end
      end

      def attributes_for_update
        { :periodicly => @periodicly }
      end

      def items_need_to_buy
        items = []
        current_time = Time.now.to_i
        if @periodicly[:next_trigger] < Time.now.to_i
          # ищем товары, срок которых подошел
          @periodicly[:item_times_to_buy].each do |item_id, time|
            if time<current_time
              items << item_id
            end
          end
        end
        items
      end

      private

      def default_history
        { :views => 0, :purchase => 0 }
      end
    end
  end
end
