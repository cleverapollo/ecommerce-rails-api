module SectoralAlgorythms
  module Child
    class ChildHelper

      # Типы товаров
      ITEM_TYPES = %w(cloth shoe sock pantyhose toy education food nappy hygiene furniture school transport)
      SIZE_TYPES = %w(cloth shoe sock pantyhose)

      class << self
        def fetch_child(item, children)
          child = {'gender'=>{}, 'age'=>{}, 'size'=>{}, 'approved'=>false}
          if children.empty?
            # Если детей нет, создадим нового
            children << child
          else
            # Поищем ребенка
            current_child_index = search_not_approved_child(item, children)
            if current_child_index.nil?
              # не нашли, создадим
              children << child
            end
          end

          children
        end

        def search_not_approved_child(item, children)
          # находим незаппрувленного ребенка (должен быть всего 1), или nil
          children.index { |child|
              return !child[:approved] if child[:approved].present?

              false
          }

        end
      end
    end
  end
end
