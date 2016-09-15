class VisitTracker

  attr_accessor :shop

  def initialize(shop)
    @shop = shop
  end

  # Засчитывает визит пользователя за текущий день.
  # @param user [User]
  def track(user)
    date = Date.current
    visit = Visit.find_by user_id: user.id, shop_id: shop.id, date: date
    if visit
      visit.increment! :pages
    else
      # Может быть дубликат при параллельных запросах, но в этом случае количество визитов уже установлено в 1, поэтому повторный запрос не делаем
      begin
        Visit.create user_id: user.id, shop_id: shop.id, date: date
      rescue PG::UniqueViolation => e
      end
    end
  end


end