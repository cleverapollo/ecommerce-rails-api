class UserProfile::Gender

  GENDERS = %w(m f)

  class << self

    # Возвращает противоложный пол
    # @param gender [String]
    # @return String
    def opposite_gender(gender)
      (GENDERS - [gender]).first
    end

    # Проверяет валидность пола
    # @param gender [String]
    # @return Boolean
    def valid_gender?(gender)
      GENDERS.include?(gender)
    end

  end

end