##
# Класс, представляющий собой предпочтения пользователя. Используется для холодного старта рекомендера.
#
class MahoutPreferences
  def initialize(user_id, shop_id, item_id = nil)
    @user_id = user_id
    @shop_id = shop_id
    @item_id = item_id
  end

  def fetch(limit = 10)
    result = []

    if @item_id.present?
      result << @item_id
    end

    # Отключили, разобраться для чего это вообще и придумать как использовать кликхаус
    #result += Action.where(user_id: @user_id, shop_id: @shop_id).order('rating desc').order('timestamp desc').limit(limit).pluck(:item_id)

    result.uniq
  end
end
