##
# Класс, сливающий пользователей.
# Как правило это происходит, когда ранее существующий пользователь логинится в магазине с другого браузера или компа.
# Происходит перелинковка связанных сущностей.
#
class UserMerger
  DEPENDENCIES = [Client, Action, MahoutAction, Session, Order, Interaction]
  # @noff: закомментировал в качестве проверки тормозов
  # DEPENDENCIES = [Client, Action, Session, Order, Interaction]

  class << self
    def merge(master, slave)
      raise ArgumentError, "Expected User, got #{master.class}" if master.class != User
      raise ArgumentError, "Expected User, got #{slave.class}" if slave.class != User

      begin
        slave.merging_lock.lock {
          DEPENDENCIES.each do |dependency|
            dependency.public_send(:relink_user, from: slave, to: master)
          end

          # сливаем виртуальный профиль
          SectoralAlgorythms::Service.new(master, SectoralAlgorythms::Service.all_algorythms)
              .merge(slave)

          slave.delete

          master
        }
      rescue Redis::Lock::LockTimeout
        # Обработка уже ведется - ничего делать не нужно.
      end

      master
    end
  end
end
