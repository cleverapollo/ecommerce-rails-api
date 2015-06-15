##
# Сохранить аттрибут пользовательского профиля
#
module UserProfile
  class AttributesProcessor
    def self.process(shop, user, attributes)
      attributes.stringify_keys!

      exists = false
      user.profile_attributes.where(shop: shop).find_each do |profile_attribute|
        exists = true if profile_attribute.value == attributes
      end
      user.profile_attributes.create!(shop: shop, value: attributes) unless exists

      # Проверяем на наличие email
      if attributes['email'].present?
        if email = IncomingDataTranslator.email(attributes['email'])
          # И сохраняем
          client = shop.clients.find_or_create_by!(user_id: user.id)
          client.email = email
          client.save
        end
      end

    end
  end
end
