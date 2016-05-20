class CreateSubscribeForCategories < ActiveRecord::Migration
  def change
    create_table :subscribe_for_categories do |t|
      t.integer :shop_id
      t.integer :user_id, limit: 8
      t.integer :item_category_id, limit: 8
      t.datetime :subscribed_at
    end
    add_index :subscribe_for_categories, [:shop_id, :user_id], name: :index_category_subscription_for_triggers
    add_index :subscribe_for_categories, [:shop_id, :subscribed_at], name: :index_category_subscription_for_cleanup
    add_index :subscribe_for_categories, [:shop_id, :user_id, :item_category_id], unique: true, name: :index_category_subscription_uniq
  end
end
