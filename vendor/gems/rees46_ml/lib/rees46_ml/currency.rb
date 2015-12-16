module Rees46ML
  class Currency < Rees46ML::Element
    TYPES = %w[RUR RUB USD BYR KZT EUR UAH]

    attribute :id,   String, default: "", lazy: false
    attribute :rate, String, default: "", lazy: false
    attribute :plus, String, default: "", lazy: false

    validates :id, presence: true, inclusion: TYPES
  end
end
