module Rees46ML
  class Param < Rees46ML::Element
    attribute :name, Rees46ML::SafeString
    attribute :unit, Rees46ML::SafeString
    attribute :value, Rees46ML::SafeString

    alias_method :param, :value
    alias_method :param=, :value=
  end
end