module Rees46ML
  class PartType < Rees46ML::Element
    attribute :value, Rees46ML::SafeString

    alias_method :part_type, :value
    alias_method :part_type=, :value=
  end
end