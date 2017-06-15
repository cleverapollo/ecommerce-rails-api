class UserProfile::Date

  FORMAT = "%Y-%m-%d"

  class << self

    # Возвращает тип дата
    # @param date [String]
    # @return Date
    def date_format(date)
      Date.strptime(date, FORMAT)
    rescue ArgumentError
      nil
    rescue TypeError
      nil
    end

    # Проверяет валидность даты
    # @param date [String]
    # @return Boolean
    def valid_date?(date)
      Date.strptime(date, FORMAT)
      true
    rescue ArgumentError
      false
    rescue TypeError
      false
    end

    # Проверяет валидность даты ребёнка
    # @param date [String]
    # @return Boolean
    def valid_child_date?(date)
      Date.strptime(date, FORMAT) > 18.years.ago
    rescue ArgumentError
      false
    rescue TypeError
      false
    end


  end

end
