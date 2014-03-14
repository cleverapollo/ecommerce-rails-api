class RemoveBotData < ActiveRecord::Migration
  def change
    bot_user_ids = Session.where("useragent ILIKE '%bot%'").pluck(:user_id)
    Action.where(user_id: bot_user_ids).destroy_all
    Session.where(user_id: bot_user_ids).destroy_all
    User.where(id: bot_user_ids).destroy_all
  end
end
