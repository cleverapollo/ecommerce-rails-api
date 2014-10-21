##
# Класс, обрабатывающий приходящие параметры от битых данных
#
class ParamsSanitizer
  def self.sanitize!(params)
    if params.is_a? Hash
      params.each do |key, value|
        if value.is_a? Hash
          ParamsSanitizer.sanitize!(params[key])
        elsif value.is_a? Array
          params[key] = value.map{|v| ParamsSanitizer.sanitize!(v) }
        else
          params[key] = ParamsSanitizer.sanitize_value(value)
        end
      end
    else
      ParamsSanitizer.sanitize_value(params)
    end
  end

  def self.sanitize_value(value)
    if value.is_a? String
      value.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => ''})
    else
      value
    end
  end
end
