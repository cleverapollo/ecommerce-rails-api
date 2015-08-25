require 'matrix'
##
# Расчет пола пользователя
#
module SectoralAlgorythms
  module Wear
    class Gender < SectoralAlgorythms::Base
      K_VIEW = 1
      K_PURCHASE = 10
      MIN_VIEWS_SCORE = 1

      def initialize(user)
        super
        @gender = user.gender
      end

      def value
        return { m: @gender['m'], f: @gender['f'] }
      end

      def trigger_view(item)
        increment_history(item, 'views')
      end

      def trigger_purchase(item)
        increment_history(item, 'purchase')
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
            # Нормализуем
            normalized_purchase = NormalizeHelper.normalize_or_flat([history['m']['purchase'], history['f']['purchase']])

            # Минимальное значение просмотров чтобы избежать категоричных оценок новых пользователей
            normalized_views = NormalizeHelper.normalize_or_flat([history['m']['views'], history['f']['views']], min_value: MIN_VIEWS_SCORE)

            @gender['m']=normalized_views[0] * K_VIEW + normalized_purchase[0] * K_PURCHASE
            @gender['f']=normalized_views[1] * K_VIEW + normalized_purchase[1] * K_PURCHASE

            normalized_gender = NormalizeHelper.normalize_or_flat([@gender['m'], @gender['f']])

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
        return relation.where('gender!=? or gender IS NULL', opposite_gender_loc) if opposite_gender_loc
        relation
      end

      def opposite_gender
        cur_gender = value
        return false if cur_gender[:m]==cur_gender[:f]
        cur_gender.min_by { |_, v| v }.first.to_s
      end

      def fix_value(gender)
        @gender[gender]=100
        @gender[opposite_gender]=0
        @gender['fixed']=true
      end

      private

      def default_history
        { 'm' => { 'views' => 0, 'purchase' => 0 }, 'f' => { 'views' => 0, 'purchase' => 0 } }
      end
    end
  end
end
