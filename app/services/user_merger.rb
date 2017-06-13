##
# Класс, сливающий пользователей.
# Как правило это происходит, когда ранее существующий пользователь логинится в магазине с другого браузера или компа.
# Происходит перелинковка связанных сущностей.
#
class UserMerger
  DEPENDENCIES = [Client, Action, MahoutAction, Session, Order, Interaction, ProfileEvent, SubscribeForCategory, SubscribeForProductAvailable, SubscribeForProductPrice, Visit, ClientCart]

  class << self
    # @param [User] master
    # @param [User] slave
    def merge(master, slave)
      raise ArgumentError, "Expected User, got #{master.class}" if master.class != User
      raise ArgumentError, "Expected User, got #{slave.class}" if slave.class != User

      begin
        slave.merging_lock.lock {
          master.merging_lock.lock {

          # Если случайно не склеиваем профиль с самим собой (у одного пользователя может быть несколько клиентов с одинаковым e-mail)
          if slave.id != master.id

            DEPENDENCIES.each do |dependency|
              dependency.public_send(:relink_user, from: slave, to: master)
            end

            # Сливаем виртуальный профиль
            properties_to_update = Hash.recursive
            properties_to_update[:gender] = UserProfile::PropertyCalculator.new.calculate_gender master
            properties_to_update[:fashion_sizes] = UserProfile::PropertyCalculator.new.calculate_fashion_sizes master
            properties_to_update[:cosmetic][:hair] = UserProfile::PropertyCalculator.new.calculate_hair master
            properties_to_update[:allergy] = UserProfile::PropertyCalculator.new.calculate_allergy master
            properties_to_update[:cosmetic][:skin] = UserProfile::PropertyCalculator.new.calculate_skin master
            properties_to_update[:children] = UserProfile::PropertyCalculator.new.calculate_children master
            properties_to_update[:compatibility] = UserProfile::PropertyCalculator.new.calculate_compatibility master
            properties_to_update[:vds] = UserProfile::PropertyCalculator.new.calculate_vds master
            properties_to_update[:pets] = UserProfile::PropertyCalculator.new.calculate_pets master
            master.update properties_to_update

            # Удаляем дочерний элемент
            slave.delete

            # Запускаем дополнительную проверку, для слияния пользователей,
            # т.к. в одно время может придти запрос при котором запуститься слияние и запрос с заказом
            UserMergeRemnantsWorker.perform_at(15.seconds.from_now, master.id, slave.id)

          end

          master

          }
        }
      rescue Redis::Lock::LockTimeout
        Rails.logger.debug " * user locked, skip: #{slave.id}"
        # Обработка уже ведется - ничего делать не нужно.
      end

      master
    end

    def merge_remnants(master_id, slave_id)
      begin
        master = User.find master_id
        if slave_id != master.id
          DEPENDENCIES.each do |dependency|
            dependency.public_send(:relink_user_remnants, master, slave_id)
          end

          # Сливаем виртуальный профиль
          properties_to_update = Hash.recursive
          properties_to_update[:gender] = UserProfile::PropertyCalculator.new.calculate_gender master
          properties_to_update[:fashion_sizes] = UserProfile::PropertyCalculator.new.calculate_fashion_sizes master
          properties_to_update[:cosmetic][:hair] = UserProfile::PropertyCalculator.new.calculate_hair master
          properties_to_update[:allergy] = UserProfile::PropertyCalculator.new.calculate_allergy master
          properties_to_update[:cosmetic][:skin] = UserProfile::PropertyCalculator.new.calculate_skin master
          properties_to_update[:children] = UserProfile::PropertyCalculator.new.calculate_children master
          properties_to_update[:compatibility] = UserProfile::PropertyCalculator.new.calculate_compatibility master
          properties_to_update[:vds] = UserProfile::PropertyCalculator.new.calculate_vds master
          properties_to_update[:pets] = UserProfile::PropertyCalculator.new.calculate_pets master
          master.update properties_to_update
        end
      rescue ActiveRecord::RecordNotFound
        # Юзер уже потерялся, ну и ладно
      end
    end

    # Склеиваем пользователя по мылу
    # @param [Shop] shop
    # @param [Client] client
    # @param [String] user_email
    def merge_by_mail(shop, client, user_email)
      # Найдем пользователя с тем же мылом в данном магазине
      client_with_current_mail = shop.clients.where.not(id: client.id).order(id: :asc).find_by(email: user_email)
      if client_with_current_mail.present?
        UserMerger.merge(client_with_current_mail.user, client.user)
      else
        # Обновляем текущему клиенту email
        client.email = user_email
        client.atomic_save!
        client.user
      end
    end

    # Склеиваем пользователя по facebook
    # @param [Shop] shop
    # @param [Client] client
    # @param [Integer] fb_id
    # @return [Client]
    def merge_by_facebook(shop, client, fb_id)
      # Найдем пользователя с тем же в данном магазине
      client_with = shop.clients.where.not(id: client.id).order(id: :asc).find_by(fb_id: fb_id)
      if client_with.present?
        old_user = client_with.user
        UserMerger.merge(old_user, client.user)
      else
        # Обновляем текущему клиенту email
        client.fb_id = fb_id
        client.atomic_save!
        client.user
      end
    end

    # Склеиваем пользователя по vkontakte
    # @param [Shop] shop
    # @param [Client] client
    # @param [Integer] vk_id
    # @return [Client]
    def merge_by_vkontakte(shop, client, vk_id)
      # Найдем пользователя с тем же в данном магазине
      client_with = shop.clients.where.not(id: client.id).order(id: :asc).find_by(vk_id: vk_id)
      if client_with.present?
        old_user = client_with.user
        UserMerger.merge(old_user, client.user)
      else
        # Обновляем текущему клиенту email
        client.vk_id = vk_id
        client.atomic_save!
        client.user
      end
    end
  end
end
