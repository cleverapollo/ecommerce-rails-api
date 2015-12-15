module Rees46ML
  class PartType < Rees46ML::Element
    TYPES = %w[hair face body intim hand leg]

    attribute :value, String, default: "", lazy: true

    validates :value, inclusion: { in: TYPES }

    alias_method :part_type, :value
    alias_method :part_type=, :value=
  end
end