class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.references :shop, null: false
      t.references :user, null: false
      t.boolean :active, null: false, default: true
      t.boolean :declined, null: false, default: false
      t.string :email
      t.string :name

      t.timestamps
    end

    add_index :subscriptions, [:shop_id, :user_id], unique: true
  end
end
