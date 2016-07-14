##
# Класс, сливающий пользователей.
# Как правило это происходит, когда ранее существующий пользователь логинится в магазине с другого браузера или компа.
# Происходит перелинковка связанных сущностей.
#
class UserMerger
  DEPENDENCIES = [Client, Action, MahoutAction, Session, Order, Interaction, ProfileEvent, SubscribeForCategory, SubscribeForProductAvailable, SubscribeForProductPrice]

  class << self
    def merge(master, slave)
      raise ArgumentError, "Expected User, got #{master.class}" if master.class != User
      raise ArgumentError, "Expected User, got #{slave.class}" if slave.class != User

      begin
        slave.merging_lock.lock {

          # Если случайно не склеиваем профиль с самим собой (у одного пользователя может быть несколько клиентов с одинаковым e-mail)
          if slave.id != master.id

            DEPENDENCIES.each do |dependency|
              dependency.public_send(:relink_user, from: slave, to: master)
            end

            # Сливаем виртуальный профиль
            properties_to_update = {}
            properties_to_update[:gender] = UserProfile::PropertyCalculator.new.calculate_gender master
            properties_to_update[:fashion_sizes] = UserProfile::PropertyCalculator.new.calculate_fashion_sizes master
            properties_to_update[:cosmetic_hair] = UserProfile::PropertyCalculator.new.calculate_hair master
            properties_to_update[:allergy] = UserProfile::PropertyCalculator.new.calculate_allergy master
            properties_to_update[:cosmetic_skin] = UserProfile::PropertyCalculator.new.calculate_skin master
            properties_to_update[:children] = UserProfile::PropertyCalculator.new.calculate_children master
            master.update properties_to_update

            # Удаляем дочерний элемент
            slave.delete

          end

          master

        }
      rescue Redis::Lock::LockTimeout
        # Обработка уже ведется - ничего делать не нужно.
      end

      master
    end

    # Склеиваем пользователя по мылу
    def merge_by_mail(shop, client, user_email)
      # Найдем пользователя с тем же мылом в данном магазине
      if client_with_current_mail = shop.clients.where.not(id: client.id).where(email: user_email).order(id: :asc).limit(1)[0]
        old_user = client_with_current_mail.user
        UserMerger.merge(old_user, client.user)
      else
        # И при этом этого мыла больше нигде нет
        # Запоминаем его для текущего пользователя
        # Адовый способ не ломать транзакцию
        exclude_query = "NOT EXISTS (SELECT 1 FROM clients WHERE shop_id = ? and email = ?)"
        shop.clients.where(id: client.id).where(exclude_query, shop.id, user_email).update_all(email: user_email)
        client.reload.user
      end
    end
  end
end
