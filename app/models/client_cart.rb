##
# Корзины пользователей.
# Используется в триггерах и в статистике.
# Синтаксис поля items: - массив идентификаторов товаров
# Хранится в мастер-базе для возможности ремаркетинга брошенных корзин
#
class ClientCart < ActiveRecord::Base
  include RequestLogger

  belongs_to :shop
  belongs_to :user

  include UserLinkable

  before_create :set_date

  validates :shop_id, presence: true
  validates :user_id, presence: true
  validates :items, presence: true


  class << self

    # Track cart
    # @param shop [Shop]
    # @param user [User]
    # @param items [Item[]]
    def track(shop, user, items)

      # Find record
      record = self.find_by(shop_id: shop.id, user_id: user.id)

      # No record and no items - skip it
      return nil if record.nil? && items.empty?

      # Have record
      if record

        # Rewrite cart
        if items.count > 1
          record.update items: items.map(&:id)

        # Update cart or create cart (depends on SDK version)
        elsif items.count == 1

          unless record.items.include?(items.first.id)
            record.update items: (record.items << items.first.id)
          end

        elsif items.count == 0
          # Clear cart
          record.destroy
        end

      else
        # No record - create it
        begin
          self.create user_id: user.id, shop_id: shop.id, items: items.map(&:id)
        rescue ActiveRecord::RecordNotUnique
        end
      end
    end

    # Удаляет неактуальные корзины
    def clear_outdated
      where('date < ?', 1.month.ago).delete_all
    end

  end


  # Removes products from cart. And destroys if cart empty
  # @param ids [Bigint]
  def remove_from_cart(ids)
    return if ids.empty?
    if items.empty? || (items - ids).empty?
      destroy
      return
    end
    update items: (items - ids)
  end


  private

  def set_date
    self.date = Date.current if self.date.nil?
  end

end
