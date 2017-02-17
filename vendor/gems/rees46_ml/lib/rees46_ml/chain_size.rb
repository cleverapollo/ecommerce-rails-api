module Rees46ML
  class ChainSize < Rees46ML::Element

    attribute :value, String, default: ""

    alias_method :size, :value
    alias_method :size=, :value=

  end
end