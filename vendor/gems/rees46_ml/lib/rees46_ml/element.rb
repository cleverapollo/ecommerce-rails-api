module Rees46ML
  class Element
    include ActiveModel::Validations

    include Virtus.model do |model|
      model.coerce = true
      model.nullify_blank = true
    end

    attribute :usupported_elements, Array[Rees46ML::UnsupportedElement]

    def ==(other)
      self.hash == other.hash
    end

    def hash
      attributes.hash
    end
  end
end
