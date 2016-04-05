require "uri"

module Rees46ML
  class URL < Virtus::Attribute
    def coerce(value)
      value.to_s.gsub(/\A\p{Space}*/, '').strip
    end
  end
end
