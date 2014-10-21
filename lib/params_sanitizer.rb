##
# Класс, обрабатывающий приходящие параметры от битых данных
#
class ParamsSanitizer
  # Рекурсивная функция обхода входящего хэша и обработки всех строк в нем.
  # Изменяет объект по ссылке.
  # Умеет работать с массивами и вложенными хэшами.
  #
  # @param params [Hash] входящий хэш параметров
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

  # Чистит входящую строку от битых символов.
  # Если передана не строка, то возращает переданное значение обратно
  #
  # @param value [Object] входящий параметр любого типа
  # @return [Object] возвращается объект того же типа
  def self.sanitize_value(value)
    if value.is_a? String
      value.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => ''})
    else
      value
    end
  end
end
