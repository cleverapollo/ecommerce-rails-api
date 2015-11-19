##
# Пользователь.
#
class User < MasterTable
  include RequestLogger
  include Redis::Objects

  has_many :clients
  has_many :sessions
  has_many :actions
  has_many :orders
  has_many :profile_attributes

  # Редисовая блокировка. Используется при слиянии пользователей
  lock :merging, expiration: 60, timeout: 1

  def to_s
    "User ##{id}"
  end

  # Тестовая группа в магазине
  def ab_testing_group_in(shop)
    shop.clients.find_or_create_by(user_id: self.id).ab_testing_group
  end

  def profile
    Profile.find_or_create_by!(user_id:self.id)
  end
end
