class ValuesHelper
  class << self
    def present_one(new_object, old_object, attribute)
      new_object.send(attribute).present? ? new_object.send(attribute) : old_object.send(attribute)
    end

    def with_contents(new_object, old_object, attribute)
      (new_object.send(attribute).present? && new_object.send(attribute).try(:any?)) ? new_object.send(attribute) : old_object.send(attribute)
    end

    def true_one(new_object, old_object, attribute)
      new_object_value = new_object.send(attribute)
      (new_object_value != nil && new_object_value) ? new_object_value : true
    end

    def false_one(new_object, old_object, attribute)
      new_object_value = new_object.send(attribute)
      (new_object_value != nil && new_object_value) ? new_object_value : false
    end
  end
end
