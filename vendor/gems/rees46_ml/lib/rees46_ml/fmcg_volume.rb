module Rees46ML
  class FmcgVolume < Rees46ML::Element
    attribute :value, String, default: "", lazy: true
    attribute :price, String, default: "", lazy: true
    attribute :unit, String, default: "", lazy: true
  end
end