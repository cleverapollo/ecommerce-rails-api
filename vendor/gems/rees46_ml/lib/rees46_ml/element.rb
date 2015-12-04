module Rees46ML
  class Element
    include ActiveModel::Validations

    include Virtus.model do |model|
      model.coerce = true
      model.nullify_blank = true
      # model.strict = true
    end

    attribute :usupported_elements, Array[Rees46ML::UnsupportedElement]

    def with_usupported_elements?
      usupported_elements.any?
    end
  end
end
