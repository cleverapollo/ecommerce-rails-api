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
          client.update(email: email)
          # # Найдем всех пользователей с тем же мылом в данном магазине
          # clients_with_current_mail = shop.clients.where(email:email).order(id: :asc)
          # if clients_with_current_mail.size>1
          #   oldest_user = clients_with_current_mail.first.user
          #   clients_with_current_mail.each {|merge_client| UserMerger.merge(oldest_user, merge_client.user) unless merge_client.user.id==oldest_user.id }
          # end
          
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
