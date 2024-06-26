##
# Сохранить аттрибут пользовательского профиля
#
module UserProfile
  class AttributesProcessor

    # @param [Shop] shop
    # @param [User] user
    # @param [Hash] attributes
    def self.process(shop, user, attributes)
      attributes.stringify_keys!

      # Пробуем найти клиента
      # @type client [Client]
      client = shop.clients.find_by(user_id: user.id)

      # Проверяем на наличие email
      if attributes['email'].present?
        email = IncomingDataTranslator.email(attributes['email'])
        if email.present?

          # Если клиента не нашли, создадим
          if client.nil?
            client = shop.clients.create!(user_id: user.id, email: email)
          end

          # Обновляем мыло
          client.update_email(email)
        end
      end

      # Проверяем на наличие пола
      if attributes['gender'].present?
        gender = attributes['gender']
        if UserProfile::Gender.valid_gender? gender
          user.gender = gender
        end
      end

      # Если передали facebook id
      if attributes['fb_id'].present?

        # Если клиента не нашли, создадим
        if client.nil?
          client = shop.clients.create!(user_id: user.id, fb_id: attributes['fb_id'])
        else

          # Если fb id отличается, запускаем слияние
          if client.fb_id != attributes['fb_id'].to_i
            user = UserMerger.merge_by_facebook(shop, client, attributes['fb_id'].to_i)
            client = Client.find_by(shop_id: shop.id, user_id: user.id)
          end
        end

      end

      # Если передали facebook id
      if attributes['vk_id'].present?

        # Если клиента не нашли, создадим
        if client.nil?
          client = shop.clients.create!(user_id: user.id, vk_id: attributes['vk_id'])
        else

          # Если fb id отличается, запускаем слияние
          if client.vk_id != attributes['vk_id'].to_i
            user = UserMerger.merge_by_vkontakte(shop, client, attributes['vk_id'].to_i)
            client = Client.find_by(shop_id: shop.id, user_id: user.id)
          end
        end

      end

      if attributes['location'].present?
        shop_location = shop.shop_locations.find_by(external_id: attributes['location'])
        client.update location: shop_location.external_id if shop_location.present?
      end

      if attributes['kids'].present?
        ProfileEvent.track_push_attributes(user, shop, 'push_attributes_children', attributes)
      end

      user.save if user.changed?
    end
  end
end
