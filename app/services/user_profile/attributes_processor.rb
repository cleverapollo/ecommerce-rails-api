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
          else

            # Если мыло отличается, запускаем слияние
            if client.email != email
              user = UserMerger.merge_by_mail(shop, client, email)
              client = Client.find_by(shop_id: shop.id, user_id: user.id)
            end
          end
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

      user.save if user.changed?
    end
  end
end
