module Rees46ML
  class SkinType < Rees46ML::Element
    TYPES = %w[dry normal oily comby]

    attribute :value, String, default: ""

    validates :value, inclusion: { in: TYPES }

    alias_method :skin_type, :value
    alias_method :skin_type=, :value=
  end
end