module Rees46ML
  class Size < Rees46ML::Element
    ALLOWS_PREFIX = %w(r e b)
    DEFAULT_PREFIX = "u".freeze

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
      value.gsub(/[^0-9]/, '')
    end

    # Русский размер? Только в случае, если префикс r или вообще без префикса
    # @return Boolean
    def ru?
      prefix == "r" || value.match(/^[0-9]+$/)
    end

    # Префикс размера. Если не указан, считается русским и возвращает "r"
    # @return String
    def prefix
      @prefix ||= ( value.to_s[0].match(/a-z/) ? value.to_s[0] : 'r' )
    end
  end
end