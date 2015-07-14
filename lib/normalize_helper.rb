require 'matrix'
class NormalizeHelper
  class << self
    def normalize_or_flat(values, params = {})
      if params[:min_value].to_i > 0
        values.map! do |value|
          value = params[:min_value] if value<params[:min_value]
          value
        end
      end

      sum = values.reduce(:+)

      if sum == 0
        # Нормализуем по единичному вектору
        values = values.fill(1)
        sum = values.size
      end

      values.map {|val| val.to_f/sum.to_f}
    end
  end
end