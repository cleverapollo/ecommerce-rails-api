class MahoutPreferences
  def initialize(user_id)
    @user_id = user_id
    @shop_id = shop_id
  end

  def fetch(limit = 10)
    result = []

    result << Action.where(user_id: @user_id, shop_id: @shop_id).order('rating desc').order('timestamp desc').limit(10).pluck(:item_id)

    result
  end
end
