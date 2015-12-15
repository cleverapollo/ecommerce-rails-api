module Rees46ML
  class Accessory < Rees46ML::Element
    attribute :id, String, default: "", lazy: true
  end
end