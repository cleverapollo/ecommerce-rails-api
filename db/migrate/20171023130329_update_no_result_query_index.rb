class UpdateNoResultQueryIndex < ActiveRecord::Migration
  def change
    remove_index :no_result_queries, column: [:shop_id, :synonym]
    add_index :no_result_queries, [:shop_id, :query], unique: true
    add_index :no_result_queries, [:synonym]
  end
end
