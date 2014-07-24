class CreateInteractions < ActiveRecord::Migration
  def change
    create_table :interactions do |t|
      t.integer :shop_id, null: false
      t.integer :user_id, null: false
      t.integer :item_id, null: false
      t.integer :code, null: false
      t.integer :recommender_code

      t.datetime :created_at, null: false
    end
  end
end
