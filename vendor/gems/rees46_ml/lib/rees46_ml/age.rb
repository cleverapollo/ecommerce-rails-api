module Rees46ML
  class Age < Rees46ML::Element
    attribute :unit, Rees46ML::SafeString
    attribute :value, Rees46ML::SafeString

    alias_method :age,  :value
    alias_method :age=, :value=
  end
end