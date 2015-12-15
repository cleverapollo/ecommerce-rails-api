module Rees46ML
  class Price < Rees46ML::Element
    attribute :value, String, default: "", lazy: true

    alias_method :price, :value
    alias_method :price=, :value=
  end
end