module Rees46ML
  class Gender < Rees46ML::Element
    MALE = 'm'.freeze
    FEMALE = 'f'.freeze
    UNISEX = 'u'.freeze

    attribute :value, Rees46ML::SafeString, default: UNISEX

    alias_method :gender, :value
    alias_method :gender=, :value=
  end
end