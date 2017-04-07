class VisitTracker

  attr_accessor :shop

  def initialize(shop)
    @shop = shop
  end

  # Засчитывает визит пользователя за текущий день.
  # @param user [User]
  def track(user)
    Time.use_zone(shop.customer.time_zone) do
      date = Date.current

      # Пытаемся на прямую обновить, чтобы не делать дополнительных запросов
      u = Visit.connection.update(ActiveRecord::Base.send(:sanitize_sql_array, ['UPDATE visits SET pages = pages + 1 WHERE user_id = :user_id AND shop_id = :shop_id AND "date" = :date', user_id: user.id, shop_id: shop.id, date: date]))

      # Если ни одной записи не было обновлено, добавляем запись
      if u == 0
        # Может быть дубликат при параллельных запросах, но в этом случае количество визитов уже установлено в 1, поэтому повторный запрос не делаем
        Visit.connection.insert(ActiveRecord::Base.send(:sanitize_sql_array, [
            'INSERT INTO visits (user_id, shop_id, "date") VALUES(:user_id, :shop_id, :date) ON CONFLICT (user_id, shop_id, "date") DO NOTHING', user_id: user.id, shop_id: shop.id, date: date
        ]))
      end
    end
  end


end