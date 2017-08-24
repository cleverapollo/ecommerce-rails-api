##
# Пользователь.
#
class User < ActiveRecord::Base
  include RequestLogger
  include Redis::Objects

  has_many :clients
  has_many :visits
  has_many :sessions
  has_many :actions
  has_many :orders
  has_many :search_queries
  has_many :user_taxonomies
  has_many :profile_events
  has_many :subscribe_for_categories
  has_many :subscribe_for_product_prices
  has_many :subscribe_for_product_availables
  has_many :client_carts

  # Для партицируемых таблиц необходимо сначала получить ID, а потом создавать запись
  before_create :fetch_nextval

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
    Jbuilder.encode do |json|
      json.gender gender
      json.fashion do
        json.sizes fashion_sizes
      end
      json.cosmetic do
        json.hair cosmetic_hair
        json.skin cosmetic_skin
      end
      json.allergy allergy
      json.jewelry do
        json.gem (jewelry && jewelry['gem'] ? jewelry['gem'] : nil)
        json.metal (jewelry && jewelry['metal'] ? jewelry['metal'] : nil)
        json.color (jewelry && jewelry['color'] ? jewelry['color'] : nil)
        json.ring_size (jewelry && jewelry['ring_size'] ? jewelry['ring_size'] : nil)
        json.bracelet_size (jewelry && jewelry['bracelet_size'] ? jewelry['bracelet_size'] : nil)
        json.chain_size (jewelry && jewelry['chain_size'] ? jewelry['chain_size'] : nil)
      end
    end
  end

  private

  def fetch_nextval
    self.id = User.connection.select_value("SELECT nextval('users_id_seq')") unless self.id
  end

end
