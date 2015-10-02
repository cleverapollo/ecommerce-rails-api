##
# Расчет размеров детей пользователя
#
module SectoralAlgorythms
  module VirtualProfile
    module Child
      class Size < SectoralAlgorythms::Base
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

          if sizes = item.try(:sizes)


            size_params =  SizeHelper.bad_to_default(wear_type: item.wear_type,
                                                     gender: item.gender,
                                                     feature: 'child')

            current_child_index, @children = ChildHelper.fetch_child(@children)

            @children[current_child_index]['size']['history'] ||= {}

            sizes.each do |size|
              calculate_size = SizeHelper.to_ru(size.to_s, size_params)

              if calculate_size && calculate_size.to_i > 5
                @children[current_child_index]['size']['history'][size_params[:gender]]||={}
                @children[current_child_index]['size']['history'][size_params[:gender]][size_params[:wear_type]]||={}
                @children[current_child_index]['size']['history'][size_params[:gender]][size_params[:wear_type]][calculate_size] ||= default_history
                @children[current_child_index]['size']['history'][size_params[:gender]][size_params[:wear_type]][calculate_size][history_key] += 1
              end
            end
          end
        end

        def recalculate
          current_child_index, @children = ChildHelper.fetch_child(@children)
          full_history =  @children[current_child_index]['size']['history']

          return if full_history.nil? || full_history.empty?

          full_history.each do |gender, gender_history|
            gender_history.each do |wear_type, wear_type_history|
              wear_type_history.each do |_, history|
                sizes = history.keys.compact

                # Нормализуем
                normalized_purchase = NormalizeHelper.normalize_or_flat(sizes.map { |size| history[size]['purchase'] })

                # Минимальное значение просмотров - 10, чтобы избежать категоричных оценок новых пользователей
                normalized_views = NormalizeHelper.normalize_or_flat(sizes.map { |size| history[size]['views'] }, min_value: MIN_VIEWS_SCORE)

                normalized_sizes = {}
                sizes.each_with_index { |size, index| normalized_sizes[size]= normalized_views[index] * K_VIEW + normalized_purchase[index] * K_PURCHASE }

                normalized_sizes = NormalizeHelper.normalize_or_flat(normalized_sizes.values)
                max_probability_size_index = normalized_sizes.each_with_index.max[1]

                @children[current_child_index]['size'][gender]||={}
                @children[current_child_index]['size'][gender][wear_type]||={}
                @children[current_child_index]['size']['size']=sizes[max_probability_size_index]
                @children[current_child_index]['size']['probability']=(normalized_sizes[max_probability_size_index]*100).to_i
              end
            end
          end



        end

        def attributes_for_update
          { :children => @children }
        end

        def merge(slave)

        end

        private

        def default_history
          { 'views' => 0, 'purchase' => 0 }
        end
      end
    end
  end

end
