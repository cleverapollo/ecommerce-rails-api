class AddPixelsToClient < ActiveRecord::Migration
  def change
    add_column :clients, :synced_with_republer_at, :date
    add_column :clients, :synced_with_advmaker_at, :date
    add_column :clients, :synced_with_doubleclick_at, :date
    add_column :clients, :synced_with_doubleclick_cart_at, :date
    add_column :clients, :synced_with_facebook_at, :date
    add_column :clients, :synced_with_facebook_cart_at, :date
  end
end
