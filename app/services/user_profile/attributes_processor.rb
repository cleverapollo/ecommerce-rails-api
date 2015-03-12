module UserProfile
  class AttributesProcessor
    def self.process(shop, user, attributes)
      attributes.stringify_keys!
      exists = false
      user.profile_attributes.where(shop: shop).find_each do |profile_attribute|
        exists = true if profile_attribute.value == attributes
      end
      user.profile_attributes.create!(shop: shop, value: attributes) unless exists
    end
  end
end
