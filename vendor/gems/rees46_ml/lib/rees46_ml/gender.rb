module Rees46ML
  class Gender < Rees46ML::Element
    MALE = 'm'.freeze
    FEMALE = 'f'.freeze
    UNISEX = 'u'.freeze

    attribute :value, String, default: "", default: UNISEX, lazy: true

    alias_method :gender, :value
    alias_method :gender=, :value=

    validates :value, presence: true, inclusion: { in: [MALE, FEMALE, UNISEX] }
  end
end
