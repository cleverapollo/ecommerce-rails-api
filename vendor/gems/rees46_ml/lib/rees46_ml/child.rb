module Rees46ML
  class Child < Rees46ML::Element
    TYPES = %w[cloth shoe sock toy education food nappy hygiene furniture school transport]

    attribute :age, Rees46ML::ChildAge, default: ->(*){ Rees46ML::ChildAge.new }, lazy: true
    attribute :type, String, default: "", lazy: true
    attribute :brand, String, default: "", lazy: true
    attribute :sizes, Set[Rees46ML::Size], lazy: true
    attribute :gender, Rees46ML::Gender, default: ->(*){ Rees46ML::Gender.new }, lazy: true
    attribute :hypoallergenic, Rees46ML::Boolean, lazy: true
    attribute :periodic, Rees46ML::Boolean, lazy: true
    attribute :part_types, Set[Rees46ML::PartType], lazy: true
    attribute :skin_types, Set[Rees46ML::SkinType], lazy: true
    attribute :conditions, Set[String], lazy: true

    validates :gender, presence: true
    validates :type, presence: true, inclusion: { in: TYPES }

    def empty?
      type.empty? || brand.empty?
    end
  end
end
