module Rees46ML
  class Param < Rees46ML::Element
    attribute :name, String, default: "", lazy: true
    attribute :unit, String, default: "", lazy: true
    attribute :value, String, default: "", lazy: true

    alias_method :param, :value
    alias_method :param=, :value=
  end
end