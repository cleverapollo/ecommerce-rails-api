module Rees46ML
  class Age < Rees46ML::Element
    attribute :unit, String, default: "", lazy: true
    attribute :value, String, default: "", lazy: true

    alias_method :age,  :value
    alias_method :age=, :value=
  end
end