class CreateNoResultQueries < ActiveRecord::Migration
  def change
    create_table :no_result_queries do |t|
      t.integer :shop_id
      t.string :query
      t.string :synonym
      t.integer :query_count, default: 1
      t.timestamps null: false
    end

    add_index :no_result_queries, [:shop_id, :synonym], unique: true
  end
end