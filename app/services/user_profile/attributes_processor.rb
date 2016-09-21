##
# Сохранить аттрибут пользовательского профиля
#
module UserProfile
  class AttributesProcessor
    def self.process(shop, user, attributes)
      attributes.stringify_keys!

      # Проверяем на наличие email
      if attributes['email'].present?
        email = IncomingDataTranslator.email(attributes['email'])
        if email.present?
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
        if UserProfile::Gender.valid_gender? gender
          # TODO: сохранять установленный пол
        end
      end

    end
  end
end
