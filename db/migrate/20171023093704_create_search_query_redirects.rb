class CreateSearchQueryRedirects < ActiveRecord::Migration
  def change
    create_table :search_query_redirects do |t|
      t.integer :shop_id
      t.string :query 
      t.string :redirect_link
      t.timestamps null: false
    end    

    add_index :search_query_redirects, [:shop_id, :query], unique: true
  end
end
