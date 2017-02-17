module Rees46ML
  class Size < Rees46ML::Element
    ALLOWS_PREFIX = %w(r e b)
    DEFAULT_PREFIX = "u".freeze

    US_PREFIXES = %w(XXS XS S M L XL XXL XXXL)

    attribute :value, String, default: ""

    alias_method :size, :value
    alias_method :size=, :value=

    def region
      return 'r' if value.match(/^[0-9]+$/)
      return ALLOWS_PREFIX.include?(prefix) ? prefix : DEFAULT_PREFIX
    end

    # Возвращает числовое значение размера, убирая все префиксы
    # @return String
    def num
      us? ? value : value.gsub(/[^0-9]/, '')
    end

    # Русский размер? Только в случае, если префикс r или вообще без префикса
    # И при этом не американские размеры
    # @return Boolean
    def ru?
      return false if us?
      prefix == "r" || value.match(/^[0-9]+$/)
    end

    # Американский размер?
    # @return Bollean
    def us?
      US_PREFIXES.include?(value.upcase)
    end

    # Префикс размера. Если не указан, считается русским и возвращает "r"
    # Но если американский размер, возвращаем DEFAULT_PREFIX
    # @return String
    def prefix
      @prefix ||= ( us? ? (DEFAULT_PREFIX) : (value.to_s[0].match(/[a-z]?/) ? value.to_s[0] : 'r')  )
    end
  end
end