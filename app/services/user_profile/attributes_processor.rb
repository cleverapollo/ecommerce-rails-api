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
          if email.present?
            client_email = @email
            # Найдем пользователя с тем же мылом в данном магазине
            if client_with_current_mail = shop.clients.where.not(id: client.id).find_by(email: client_email)
              old_user = client_with_current_mail.user
              client_with_current_mail.each { |merge_client| UserMerger.merge(old_user, merge_client.user) unless merge_client.user.id==old_user.id }
            else
              # И при этом этого мыла больше нигде нет
              # Запоминаем его для текущего пользователя
              # Адовый способ не ломать транзакцию
              exclude_query = "NOT EXISTS (SELECT 1 FROM clients WHERE shop_id = #{shop.id} and email = '#{client_email}')"
              shop.clients.where(id: client.id).where(exclude_query).update_all(email: client_email)
            end
          end
          
        end
      end

      # Проверяем на наличие пола
      if attributes['gender'].present?
        gender = attributes['gender']
        if ['m','f'].include?(gender)
          # И сохраняем
          algo = SectoralAlgorythms::Wear::Gender.new(user)
          algo.fix_value(gender)
          user.update(algo.attributes_for_update)
        end
      end

    end
  end
end
