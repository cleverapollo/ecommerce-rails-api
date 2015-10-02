module SectoralAlgorythms
  module VirtualProfile
    module Child
      class ChildHelper

        # Типы товаров
        ITEM_TYPES = %w(cloth shoe sock toy education food nappy hygiene furniture school transport)
        SIZE_TYPES = %w(cloth shoe sock)

        class << self
          def fetch_child(children)
            child = { :gender =>{}, :age =>{}, :size =>{}, :approved =>false}
            current_child_index = 0
            if children.empty?
              # Если детей нет, создадим нового
              children << child
            else
              # Поищем ребенка
              current_child_index = search_not_approved_child(children)
              if current_child_index.nil?
                # не нашли, создадим
                children << child
                current_child_index = children.size - 1
              end
            end

            return current_child_index, children
          end

          def search_not_approved_child(children)
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
end
