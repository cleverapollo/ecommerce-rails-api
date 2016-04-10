module Rees46ML
  class Child < Rees46ML::Element
    TYPES = %w[toy education nappy furniture school transport]

    attribute :age, Rees46ML::ChildAge, default: ->(*){ Rees46ML::ChildAge.new }, lazy: true
    attribute :type, String, lazy: true
    attribute :gender, Rees46ML::Gender, lazy: true

    # Пока под вопросом
    attribute :sizes, Set[Rees46ML::Size], lazy: true
    attribute :part_types, Set[Rees46ML::PartType], lazy: true
    attribute :skin_types, Set[Rees46ML::SkinType], lazy: true
    attribute :conditions, Set[String], lazy: true


    # Тип и пол опциональны
    # validates :gender, presence: true, inclusion: { in: [MALE, FEMALE] }
    # validates :type, presence: true, inclusion: { in: TYPES }

    def type_valid?
      type.nil? || TYPES.include?(type)
    end

    def empty?
      type.nil? || type.empty?
    end
  end
end
