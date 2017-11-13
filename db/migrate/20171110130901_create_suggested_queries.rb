class CreateSuggestedQueries < ActiveRecord::Migration
  def change
    create_table :suggested_queries do |t|
      t.string :keyword
      t.string :synonym
      t.float :score
      t.integer :shop_id
      t.timestamps null: false
    end
    add_index :suggested_queries, [:shop_id, :keyword], unique: true
  end
end
