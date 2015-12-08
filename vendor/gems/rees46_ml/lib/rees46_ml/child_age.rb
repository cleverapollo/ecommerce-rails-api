module Rees46ML
  class ChildAge < Rees46ML::Element
    attribute :min, String, default: "", lazy: true
    attribute :max, String, default: "", lazy: true

    validates :min, :max, presence: true, numericality: { with: true, less_than_or_equal_to: 1.5, greater_than_or_equal_to: 0 }
  end
end