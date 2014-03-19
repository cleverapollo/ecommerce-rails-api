class CreateShopsUsers < ActiveRecord::Migration
  def change
    create_table :shops_users, id: false do |t|
      t.belongs_to :shop, null: false
      t.belongs_to :user, null: false
      t.boolean :bought_something, null: false, default: false
      t.integer :ab_testing_group
      t.timestamps
    end

    add_index :shops_users, [:shop_id, :user_id], unique: true
  end
end
