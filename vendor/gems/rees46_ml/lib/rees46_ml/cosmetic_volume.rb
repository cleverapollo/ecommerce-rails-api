module Rees46ML
  class CosmeticVolume < Rees46ML::Element
    attribute :value, Rees46ML::SafeString
    attribute :price, Rees46ML::SafeString
    attribute :unit, Rees46ML::SafeString
  end
end