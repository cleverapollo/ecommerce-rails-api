##
# Класс, сливающий пользователей.
# Как правило это происходит, когда ранее существующий пользователь логинится в магазине с другого браузера или компа.
# Происходит перелинковка связанных сущностей.
#
class UserMerger
  DEPENDENCIES = [Client, Action, Session, MahoutAction, Order, Interaction]

  class << self
    def merge(master, slave)
      raise ArgumentError, "Expected User, got #{master.class}" if master.class != User
      raise ArgumentError, "Expected User, got #{slave.class}" if slave.class != User

      begin
        slave.merging_lock.lock {
          DEPENDENCIES.each do |dependency|
            dependency.public_send(:relink_user, from: slave, to: master)
          end

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
