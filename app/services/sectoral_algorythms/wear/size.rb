##
# Расчет размера пользователя
#
module SectoralAlgorythms
  module Wear
    class Size < SectoralAlgorythms::Base
      K_VIEW = 1
      K_PURCHASE = 10
      MIN_VIEWS_SCORE = 10

      def initialize(user)
        super
        @size = user.size
      end

      def value
       {'m'=>@size['m'], 'f'=>@size['f']}
      end

      def trigger_view(item)
        increment_history(item, 'views')
      end

      def trigger_purchase(item)
        increment_history(item, 'purchase')
      end

      def increment_history(item, history_key)
        size_params =  SizeHelper.bad_to_default(wear_type: item.wear_type,
                                            gender: item.gender,
                                            feature: item.feature)

        if sizes = item.try(:sizes)
          @size['history'] ||= {}

          sizes.each do |size|
            calculate_size = SizeHelper.to_ru(size.to_s, size_params)

            if calculate_size && calculate_size.to_i > 5
              @size['history'][size_params[:gender]]||={}
              @size['history'][size_params[:gender]][size_params[:wear_type]]||={}
              @size['history'][size_params[:gender]][size_params[:wear_type]][size_params[:feature]]||={}
              @size['history'][size_params[:gender]][size_params[:wear_type]][size_params[:feature]][calculate_size] ||= default_history
              @size['history'][size_params[:gender]][size_params[:wear_type]][size_params[:feature]][calculate_size][history_key] += 1
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
              max_probability_size_index = normalized_sizes.each_with_index.max[1]

              @size[gender]||={}
              @size[gender][wear_type]||={}
              @size[gender][wear_type][feature]||={}
              @size[gender][wear_type][feature]['size']=sizes[max_probability_size_index]
              @size[gender][wear_type][feature]['probability']=(normalized_sizes[max_probability_size_index]*100).to_i
            end
          end
        end



      end

      def attributes_for_update
        { :size => @size }
      end

      private

      def default_history
        { 'views' => 0, 'purchase' => 0 }
      end
    end
  end
end