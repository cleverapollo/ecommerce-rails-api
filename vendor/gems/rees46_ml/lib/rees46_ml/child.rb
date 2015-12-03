module Rees46ML
  class Child < Rees46ML::Element
    TYPES = %w[cloth shoe sock toy education food nappy hygiene furniture school transport]

    attribute :age, Rees46ML::ChildAge, default: ->(*){ Rees46ML::ChildAge.new }
    attribute :type, Rees46ML::SafeString
    attribute :brand, Rees46ML::SafeString
    attribute :sizes, Set[Rees46ML::Size]
    attribute :gender, Rees46ML::Gender, default: ->(*){ Rees46ML::Gender.new }
    attribute :hypoallergenic, Rees46ML::Boolean
    attribute :periodic, Rees46ML::Boolean
    attribute :part_types, Set[Rees46ML::PartType]
    attribute :skin_types, Set[Rees46ML::SkinType]
    attribute :conditions, Set[Rees46ML::SafeString]

    def empty?
      type.empty? || brand.empty?
    end
  end
end
