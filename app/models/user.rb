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
  has_many :search_queries
  has_many :user_taxonomies
  has_many :profile_events
  has_many :subscribe_for_categories
  has_many :subscribe_for_product_prices
  has_many :subscribe_for_product_availables

  # Редисовая блокировка. Используется при слиянии пользователей
  lock :merging, expiration: 60, timeout: 1

  def to_s
    "User ##{id}"
  end

  # Тестовая группа в магазине
  def ab_testing_group_in(shop)
    shop.clients.find_or_create_by(user_id: self.id).ab_testing_group
  end

  # Готовит данные профиля в JSON для передачи в JS SDK
  def profile_to_json
    {
        gender: gender,
        fashion: {
            sizes: fashion_sizes
        },
        cosmetic: {
            hair: cosmetic_hair,
            skin: cosmetic_skin
        },
        allergy: allergy

    }.to_json
  end

end
