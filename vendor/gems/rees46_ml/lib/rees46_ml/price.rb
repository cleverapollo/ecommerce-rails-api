module Rees46ML
  class Price < Rees46ML::Element
    attribute :value, Rees46ML::SafeString

    alias_method :price, :value
    alias_method :price=, :value=
  end
end