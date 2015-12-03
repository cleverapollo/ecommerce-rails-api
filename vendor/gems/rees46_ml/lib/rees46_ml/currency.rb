module Rees46ML
  class Currency < Rees46ML::Element
    IDS = %w[RUR RUB USD BYR KZT EUR UAH]

    attribute :id
    attribute :rate
    attribute :plus

    validates :id, presence: true, inclusion: IDS
  end
end
