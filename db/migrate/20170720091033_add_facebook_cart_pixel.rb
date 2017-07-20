class AddFacebookCartPixel < ActiveRecord::Migration
  def change
    add_column :sessions, :synced_with_facebook_cart_at, :date
  end
end
