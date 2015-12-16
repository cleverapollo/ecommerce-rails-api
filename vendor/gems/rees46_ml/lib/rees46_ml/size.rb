module Rees46ML
  class Size < Rees46ML::Element
    ALLOWS_PREFIX = %w(r e b)
    DEFAULT_PREFIX = "u".freeze

    attribute :value, String, default: ""

    alias_method :size, :value
    alias_method :size=, :value=

    def region
      ALLOWS_PREFIX.include?(prefix) ? prefix : DEFAULT_PREFIX
    end

    def num
      value[1..-1]
    end

    def ru?
      prefix == "r"
    end

    def prefix
      @prefix ||= value.to_s[0]
    end
  end
end