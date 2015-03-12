class CreateProfileAttributes < ActiveRecord::Migration
  def change
    create_table :profile_attributes do |t|
      t.integer :user_id, null: false
      t.integer :shop_id, null: false
      t.jsonb :value, null: false

      t.timestamps null: false
    end

    add_index :profile_attributes, :user_id
  end
end
