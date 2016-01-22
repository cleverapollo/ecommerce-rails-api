##
# Сохранить аттрибут пользовательского профиля
#
module UserProfile
  class AttributesProcessor
    def self.process(shop, user, attributes)
      attributes.stringify_keys!

      # exists = false
      # user.profile_attributes.where(shop: shop).find_each do |profile_attribute|
      #   exists = true if profile_attribute.value == attributes
      # end
      # user.profile_attributes.create!(shop: shop, value: attributes) unless exists

      # Проверяем на наличие email
      if attributes['email'].present?
        if email = IncomingDataTranslator.email(attributes['email'])
          # И сохраняем
          client = shop.clients.find_or_create_by!(user_id: user.id)
          if client.email != email
            user = UserMerger.merge_by_mail(shop, client, email)
            client = Client.find_by(shop_id: shop.id, user_id: user.id)
          end
        end
      end

      # Проверяем на наличие пола
      if attributes['gender'].present?
        gender = attributes['gender']
        if ['m','f'].include?(gender)
          # И сохраняем
          algo = SectoralAlgorythms::VirtualProfile::Gender.new(user.profile)
          algo.fix_value(gender)
        end
      end

    end
  end
end
