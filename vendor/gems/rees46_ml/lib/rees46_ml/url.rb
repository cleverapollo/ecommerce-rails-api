require "uri"

module Rees46ML
  class URL < Virtus::Attribute
    def coerce(value)
      URI.parse PostRank::URI.clean(value.to_s)
    end
  end
end
