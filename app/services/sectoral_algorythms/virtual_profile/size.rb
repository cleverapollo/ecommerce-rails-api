##
# Расчет размера пользователя
#
module SectoralAlgorythms
  module VirtualProfile
    class Size < SectoralAlgorythms::VirtualProfileFieldBase
      K_VIEW = 1
      K_PURCHASE = 10
      MIN_VIEWS_SCORE = 10
      K_SIZE_DEVIATION=10

      include GenderLinkable

      def initialize(profile)
        super
        @size = @profile.size
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

        if sizes = item.try(:fashion_sizes)
          size_params = SizeHelper.bad_to_default(wear_type: item.fashion_wear_type,
                                                  gender: item.fashion_gender,
                                                  feature: item.fashion_feature)

          @size['history'] ||= {}

          sizes.each do |size|
            calculate_size = SizeHelper.to_ru(size.to_s, size_params)

            if calculate_size && calculate_size.to_i > 5
              @size['history'][size_params[:gender]]||={}
              @size['history'][size_params[:gender]][size_params[:wear_type]]||={}
              @size['history'][size_params[:gender]][size_params[:wear_type]][size_params[:feature]]||={}
              @size['history'][size_params[:gender]][size_params[:wear_type]][size_params[:feature]][calculate_size.to_s] ||= default_history
              @size['history'][size_params[:gender]][size_params[:wear_type]][size_params[:feature]][calculate_size.to_s][history_key] += 1
            end
          end
        end
      end

      def recalculate
        full_history = @size['history']

        return if full_history.nil? || full_history.empty?


        full_history.each do |gender, gender_history|
          gender_history.each do |wear_type, wear_type_history|
            wear_type_history.each do |feature, history|
              sizes = history.keys.compact

              # Нормализуем
              normalized_purchase = NormalizeHelper.normalize_or_flat(sizes.map { |size| history[size]['purchase'] })


              # Минимальное значение просмотров - 10, чтобы избежать категоричных оценок новых пользователей
              normalized_views = NormalizeHelper.normalize_or_flat(sizes.map { |size| history[size]['views'] }, min_value: MIN_VIEWS_SCORE)

              normalized_sizes = {}
              sizes.each_with_index { |size, index| normalized_sizes[size]= normalized_views[index] * K_VIEW + normalized_purchase[index] * K_PURCHASE }

              normalized_sizes = NormalizeHelper.normalize_or_flat(normalized_sizes.values)

              # Если просмотры всех размеров одинаковы (первый просмотр товара), то выбираем среднее значение, иначе максимальное
              if normalized_sizes.uniq.length == 1
                max_probability_size_index = (normalized_sizes.length / 2.0).floor
              else
                max_probability_size_index = normalized_sizes.each_with_index.max[1]
              end

              @size[gender]||={}
              @size[gender][wear_type]||={}
              @size[gender][wear_type][feature]||={}
              @size[gender][wear_type][feature]['size'] = sizes[max_probability_size_index]
              @size[gender][wear_type][feature]['probability'] = (normalized_sizes[max_probability_size_index]*100).to_i
            end
          end
        end

      end

      def merge(slave)
        if @size && @size['history'].present?
          if slave.size['history'].present?
            slave_history = slave.size['history']
            master_history = @size['history']
            @size['history'] = merge_history(master_history, slave_history) do |master_value, slave_value|
              master_value.to_i+slave_value.to_i
            end
          end
        else
          # У мастера истории нет, поэтому перезаписываем слейвом
          @size['history'] = slave.size['history'] if slave.size['history'].present?
        end
      end

      def attributes_for_update
        { :size => @size }
      end

      def modify_relation(relation)
        #{"f"=>{"shirt"=>{"adult"=>{"size"=>"48", "probability"=>100}}}

        if gender = current_gender
          type_sizes = @size[gender]
          addition_relations = []
          type_sizes.each do |type, feature|
            feature.each do |_, feature_sizes|
              size = feature_sizes['size'].to_i
              probability = feature_sizes['probability']
              deviation = ((100-probability)/K_SIZE_DEVIATION).to_i
              sizes = []
              # берем размеры, кратные 2 (особенность русской сетки)
              (size-deviation..size+deviation).each { |size_value| sizes<<size_value if size_value.even? }

              # Разные типы - разные размеры
              addition_relations << type_size_condition(type, sizes)
            end
          end if type_sizes
          relation =  relation.where(addition_relations.join(" OR ")).where.not(fashion_sizes:nil)
        end

        relation
      end

      def type_size_condition(type, sizes)
        "(fashion_wear_type='#{type}' AND  '{#{sizes.map { |size| "\"#{size}\"" }.join(',')}}' && fashion_sizes )"
      end

      def filter_by_sizes_with_rollback(relation, type, sizes)
        modified_relation = relation.where(type_size_condition(type, sizes)).where.not(fashion_sizes:nil)
        first_result = modified_relation.limit(1)[0]
        if first_result
          modified_relation
        else
          relation
        end

      end

      def value
        {m:@size['m'], f:@size['f']}
      end

      private

      def default_history
        { 'views' => 0, 'purchase' => 0 }
      end
    end
  end
end
