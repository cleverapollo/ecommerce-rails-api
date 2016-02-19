require 'matrix'
##
# Расчет пола пользователя
#
module SectoralAlgorythms
  module VirtualProfile
    class Gender < SectoralAlgorythms::VirtualProfileFieldBase
      K_VIEW = 1
      K_PURCHASE = 10
      MIN_VIEWS_SCORE = 1

      include GenderLinkable

      def initialize(profile)
        super
        @gender = @profile.gender
      end

      def value
        return { m: @profile.gender['m'], f: @profile.gender['f'] }
      end

      def trigger_view(item)
        link_gender(item)
        increment_history(item, 'views')
        ProfileEvent.track item, 'views'
      end

      def trigger_purchase(item)
        # Ищем связанный профиль противоположного пола
        link_create_gender(item)
        increment_history(item, 'purchase')
        ProfileEvent.track item, 'purchases'
      end

      def increment_history(item, history_key)
        if item.try(:gender)
          @gender['history'] ||= default_history
          @gender['history'][item.gender][history_key] += 1 if @gender['history'][item.gender].present?
        end
      end

      def recalculate
        # Не пересчитываем, если пол зафиксирован
        unless @gender['fixed']
          history = @gender['history']

          if history

            normalized_gender = []
            #Если есть покупки - считаем только по ним
            if history['m']['purchase'] + history['f']['purchase'] > 0
              # Нормализуем
              normalized_gender = NormalizeHelper.normalize_or_flat([history['m']['purchase'], history['f']['purchase']])
            else
              # Минимальное значение просмотров чтобы избежать категоричных оценок новых пользователей
              normalized_gender = NormalizeHelper.normalize_or_flat([history['m']['views'], history['f']['views']], min_value: MIN_VIEWS_SCORE)
            end

            @gender['m']=(normalized_gender[0] * 100).to_i
            @gender['f']=(normalized_gender[1] * 100).to_i
          end
        end
      end

      def attributes_for_update
        { :gender => @gender }
      end

      def modify_relation(relation)
        opposite_gender_loc = opposite_gender
        filter_by_opposite_gender(opposite_gender_loc, relation)
      end

      def filter_by_opposite_gender(gender, relation)
        return relation.where('gender!=? or gender IS NULL', gender) if gender
        relation
      end

      def filter_by_gender(gender, relation)
        opposite_gender_loc = false

        opposite_gender_loc = 'f' if gender.to_s=='m'
        opposite_gender_loc = 'm' if gender.to_s=='f'

        filter_by_opposite_gender(opposite_gender_loc, relation)
      end

      def opposite_gender
        cur_gender = value
        return false if cur_gender[:m]==cur_gender[:f]
        cur_gender.min_by { |_, v| v }.first.to_s
      end

      def fix_value(gender)
        @gender[gender]=100
        opposite_gender_loc = false
        opposite_gender_loc = 'f' if gender.to_s=='m'
        opposite_gender_loc = 'm' if gender.to_s=='f'
        if opposite_gender_loc
          @gender[opposite_gender_loc]=0
          @gender['fixed']=true
        end
        @profile.update(attributes_for_update)
      end

      def merge(slave)
        if @gender && @gender['history'].present?
          # Сливаем суммированием истории
          if slave.gender['history'].present?
            slave_history = slave.gender['history']
            master_history = @gender['history']
            @gender['history'] = merge_history(master_history, slave_history) do |master_value, slave_value|
              master_value.to_i+slave_value.to_i
            end
          end
        else
          # У мастера истории нет, поэтому перезаписываем слейвом
          @gender['history'] = slave.gender['history'] if slave.gender['history'].present?
        end
      end

      private

      def default_history
        { 'm' => { 'views' => 0, 'purchase' => 0 }, 'f' => { 'views' => 0, 'purchase' => 0 } }
      end
    end
  end
end
