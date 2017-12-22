##
# Класс, сливающий пользователей.
# Как правило это происходит, когда ранее существующий пользователь логинится в магазине с другого браузера или компа.
# Происходит перелинковка связанных сущностей.
# @deprecated
class UserMerger
  DEPENDENCIES = [Client, MahoutAction, Session, Order, Interaction, ProfileEvent, SubscribeForProductAvailable, SubscribeForProductPrice, ClientCart]

  class << self
    # @param [User] master
    # @param [User] slave
    # @deprecated
    def merge(master, slave)
      raise 'User merger deprecated'
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
            update_master(master)

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

    # Сливает возможные остатки удаленного юзера
    # @param [Integer] master_id
    # @param [Integer] slave_id
    def merge_remnants(master_id, slave_id)
      begin
        master = User.find master_id
        if slave_id != master.id
          DEPENDENCIES.each do |dependency|
            dependency.public_send(:relink_user_remnants, master, slave_id)
          end
          update_master(master)
        end
        master
      rescue ActiveRecord::RecordNotFound
        # Юзер уже потерялся, ну и ладно
      end
    end

    # Склеиваем пользователя по мылу
    # @param [Shop] shop
    # @param [Client] client
    # @param [String] user_email
    # @deprecated
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


    private

    def update_master(master)
      # Сливаем виртуальный профиль
      master.gender = UserProfile::PropertyCalculator.new.calculate_gender master.id
      master.fashion_sizes = UserProfile::PropertyCalculator.new.calculate_fashion_sizes master
      master.cosmetic_hair = UserProfile::PropertyCalculator.new.calculate_hair master
      master.allergy = UserProfile::PropertyCalculator.new.calculate_allergy master
      master.cosmetic_skin = UserProfile::PropertyCalculator.new.calculate_skin master
      master.cosmetic_perfume = UserProfile::PropertyCalculator.new.calculate_perfume master
      master.children = UserProfile::PropertyCalculator.new.calculate_children master
      master.compatibility = UserProfile::PropertyCalculator.new.calculate_compatibility master
      master.vds = UserProfile::PropertyCalculator.new.calculate_vds master
      master.pets = UserProfile::PropertyCalculator.new.calculate_pets master
      master.realty = UserProfile::PropertyCalculator.new.calculate_realty master
      master.atomic_save! if master.changed?
    end
  end
end
