require 'matrix'
##
# Расчет пола детей пользователя
#
module SectoralAlgorythms
  module Child
    class Gender < SectoralAlgorythms::Base
      K_VIEW = 1
      K_PURCHASE = 10
      MIN_VIEWS_SCORE = 10


      def initialize(user)
        super
        @children = user.children
      end

      def value
        return @children
      end

      def trigger_view(item)
        increment_history(item, 'views')
      end

      def trigger_purchase(item)
        increment_history(item, 'purchase')
      end

      def increment_history(item, history_key)
        if item.try(:gender)
          # определим в какого ребенка производим запись
          current_child_index, @children = ChildHelper.fetch_child(@children)

          @children[current_child_index]['gender']['history'] ||= default_history
          @children[current_child_index]['gender'][item.gender][history_key] += 1 if @children[current_child_index]['gender'][item.gender].present?
        end
      end

      def recalculate
        current_child_index, @children = ChildHelper.fetch_child(@children)
        history =  @children[current_child_index]['gender']['history']

        if history
          # Нормализуем
          normalized_purchase = NormalizeHelper.normalize_or_flat([history['m']['purchase'], history['f']['purchase']])

          # Минимальное значение просмотров - 10, чтобы избежать категоричных оценок новых пользователей
          normalized_views = NormalizeHelper.normalize_or_flat([history['m']['views'], history['f']['views']], min_value:MIN_VIEWS_SCORE)

          @children[current_child_index]['gender']['m']=normalized_views[0] * K_VIEW + normalized_purchase[0] * K_PURCHASE
          @children[current_child_index]['gender']['f']=normalized_views[1] * K_VIEW + normalized_purchase[1] * K_PURCHASE

          normalized_gender = NormalizeHelper.normalize_or_flat([@gender['m'], @gender['f']])

          @children[current_child_index]['gender']['m']=(normalized_gender[0] * 100).to_i
          @children[current_child_index]['gender']['f']=(normalized_gender[1] * 100).to_i
        end
      end

      def attributes_for_update
        { :children => @children }
      end

      private

      def default_history
        { 'm' => { 'views' => 0, 'purchase' => 0 }, 'f' => { 'views' => 0, 'purchase' => 0 } }
      end


    end
  end
end
