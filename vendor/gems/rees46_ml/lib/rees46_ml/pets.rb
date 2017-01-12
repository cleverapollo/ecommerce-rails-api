module Rees46ML
  class Pets < Rees46ML::Element
    TYPES = %w[dog cat bird fish]
    AGES = %w[young middle old]
    SIZES = %w[small medium large]

    attribute :pet_age, String, lazy: true
    attribute :pet_size, String, lazy: true
    attribute :breed, String, lazy: true
    attribute :pet_type, String, lazy: true
    attribute :periodic, Rees46ML::Boolean, lazy: true

    def type_valid?
      pet_type.nil? || TYPES.include?(pet_type)
    end

    def age_valid?
      pet_age.nil? || AGES.include?(age)
    end

    def size_valid?
      pet_size.nil? || SIZES.include?(pet_size)
    end

  end
end
