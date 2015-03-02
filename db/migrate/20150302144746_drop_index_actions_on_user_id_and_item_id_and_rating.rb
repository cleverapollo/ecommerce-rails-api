class DropIndexActionsOnUserIdAndItemIdAndRating < ActiveRecord::Migration
  def change
    execute "DROP INDEX index_actions_on_user_id_and_item_id_and_rating;"
  end
end
