class SizeHelper

  # Типоразмеры
  SIZE_TYPES = %w(shoe shirt tshirt underwear trouser jacket blazer sock belt hat glove)

  # Свойства
  FEATURES = %w(child pregnant adult)

  # Значения по умолчанию
  DEFAULT_VALUES = { gender: 'm', wear_type: 'tshirt', feature: 'adult' }


  def self.to_ru(size, params={})

    calculate_size = size.to_s

    # Пришло число, преобразований не требуется
    return calculate_size.to_i if numeric?(calculate_size)

    # Регион размера
    size_region = size_region(calculate_size)

    if size_region == 'r'
      # Уже русский, преобразование не требуется
      calculate_size[0] = ''
      return calculate_size.to_i
    else
      # Доберем информации для генерации имени метода

      # генерируем класс и пытаемся найти значение
      table_class = "SizeTables::#{params[:wear_type].camelcase}".constantize

      if table_class.respond_to?(:new)
        calculate_size[0]='' unless size_region=='u'
        return table_class.new.value(params[:gender], size_region, params[:feature], calculate_size).to_i
      else
        return nil
      end
    end
  end

  # Регион размера
  def self.size_region(size)
    prefix = size[0]
    return prefix if %w(r e b).include? prefix
    return 'u'
  end

  def self.bad_to_default(params)
    result = {}
    result[:wear_type] = if params[:wear_type] && SIZE_TYPES.include?(params[:wear_type])
                           params[:wear_type]
                         else
                           DEFAULT_VALUES[:wear_type]
                         end

    result[:gender] = if params[:gender] && ['m', 'f'].include?(params[:gender])
                        params[:gender]
                      else
                        DEFAULT_VALUES[:gender]
                      end

    result[:feature] = if params[:feature] && FEATURES.include?(params[:feature])
                         params[:feature]
                       else
                         DEFAULT_VALUES[:feature]
                       end
    result
  end

  def self.numeric?(val)
    return true if val =~ /\A\d+\Z/
    true if Float(val) rescue false
  end


end