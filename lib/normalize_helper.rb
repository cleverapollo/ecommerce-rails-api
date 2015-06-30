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
      vector = Vector.elements(values)
      if vector.magnitude == 0
        # Нормализуем по единичному вектору
        vector = Vector.elements(values.fill(1))
      end

      vector.normalize
    end
  end
end