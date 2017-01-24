module Rees46ML
  class Compatibility < Rees46ML::Element
    attribute :brand, String, default: "", lazy: true
    attribute :model, String, default: "", lazy: true
  end
end