class AddIndexToSearchQueries < ActiveRecord::Migration
  def change
    add_index :search_queries, [:shop_id, :date, :user_id]
  end
end
