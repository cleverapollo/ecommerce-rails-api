##
# Расчет размера пользователя
#
module SectoralAlgorythms
  module VirtualProfile
    class Physiology < SectoralAlgorythms::VirtualProfileFieldBase
      K_VIEW = 1
      K_PURCHASE = 10

      MIN_VIEWS_SCORE = 10
      MIN_HYPPALGENIC_SCORE = 30

      include GenderLinkable

      PART_TYPES=['hair', 'face', 'body', 'intim', 'hand', 'leg']

      def initialize(profile)
        super
        @physiology = @profile.physiology
      end

      def trigger_view(item)
        link_gender(item)
        increment_history(item, 'views')
      end

      def trigger_purchase(item)
        link_create_gender(item)
        increment_history(item, 'purchase')
      end

      def increment_history(item, history_key)

        part_types = item.try(:part_type)
        gender = item.try(:gender)

        if part_types && gender
          @physiology['history'] ||= {}
          part_types.each do |part_type|
            if part_type && PART_TYPES.include?(part_type)

              @physiology['history'][gender]||={}
              @physiology['history'][gender][part_type]||={}

              if skin_types=item.try(:skin_type)
                @physiology['history'][gender][part_type]['skin_type']||={}
                skin_types.each do |skin_type|
                  @physiology['history'][gender][part_type]['skin_type'][skin_type]||= default_history
                  @physiology['history'][gender][part_type]['skin_type'][skin_type][history_key] += 1
                end
              end

              if conditions=item.try(:condition)
                @physiology['history'][gender][part_type]['condition']||={}
                conditions.each do |condition|
                  @physiology['history'][gender][part_type]['condition'][condition]||= default_history
                  @physiology['history'][gender][part_type]['condition'][condition][history_key] += 1
                end
              end

              hypoallergenic=item.try(:hypoallergenic)

              if hypoallergenic.present?
                @physiology['history'][gender][part_type]['hypoallergenic']||={}
                @physiology['history'][gender][part_type]['hypoallergenic'][hypoallergenic.to_s]||= default_history
                @physiology['history'][gender][part_type]['hypoallergenic'][hypoallergenic.to_s][history_key] += 1
              end

            end
          end
        end
      end


      def recalculate
        full_history = @physiology['history']

        return if full_history.nil? || full_history.empty?

        full_history.each do |gender, gender_history|
          gender_history.each do |part_type, part_type_history|
            part_type_history.each do |feature, history|

              min_views_score = MIN_VIEWS_SCORE
              # Гипоалергенные товары имеют большее запаздывание
              min_views_score = MIN_HYPPALGENIC_SCORE if feature=='hypoallergenic'

              values = history.keys.compact

              # Нормализуем
              normalized_purchase = NormalizeHelper.normalize_or_flat(values.map { |value| history[value]['purchase'] })

              # Минимальное значение просмотров - 10, чтобы избежать категоричных оценок новых пользователей
              normalized_views = NormalizeHelper.normalize_or_flat(values.map { |value| history[value]['views'] }, min_value: min_views_score)

              normalized_values = {}
              values.each_with_index { |value, index| normalized_values[value]= normalized_views[index] * K_VIEW + normalized_purchase[index] * K_PURCHASE }

              normalized_values = NormalizeHelper.normalize_or_flat(normalized_values.values)
              max_probability_value_index = normalized_values.each_with_index.max[1]

              @physiology[gender]||={}
              @physiology[gender][part_type]||={}
              @physiology[gender][part_type][feature]||={}
              @physiology[gender][part_type][feature]['value']=values[max_probability_value_index]
              @physiology[gender][part_type][feature]['probability']=(normalized_values[max_probability_value_index]*100).to_i

            end
          end
        end

      end

      def merge(slave)
        if @physiology && @physiology['history'].present?
          if slave.physiology['history'].present?
            slave_history = slave.physiology['history']
            master_history = @physiology['history']
            @physiology['history'] = merge_history(master_history, slave_history) do |master_value, slave_value|
              master_value.to_i+slave_value.to_i
            end
          end
        else
          # У мастера истории нет, поэтому перезаписываем слейвом
          @physiology['history'] = slave.physiology['history'] if slave.physiology['history'].present?
        end
      end


      def attributes_for_update
        { :physiology => @physiology }
      end

      def value
        {m:@physiology['m'], f:@physiology['f']}
      end

      private

      def default_history
        { 'views' => 0, 'purchase' => 0 }
      end
    end
  end
end
