module Rees46ML
  class Gender < Rees46ML::Element
    MALE = 'm'.freeze
    FEMALE = 'f'.freeze

    attribute :value, String, default: nil, lazy: true

    alias_method :gender, :value
    alias_method :gender=, :value=

    validates :value, presence: true, inclusion: { in: [MALE, FEMALE] }

    def valid?
      value.nil? || [MALE, FEMALE].include?(value)
    end

  end
end
