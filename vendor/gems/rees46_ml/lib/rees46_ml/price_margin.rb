module Rees46ML
  class PriceMargin < Rees46ML::Element
    attribute :value, Integer, default: null, lazy: true

    alias_method :price_margin, :value
    alias_method :price_margin=, :value=
  end
end