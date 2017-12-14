class AddBouncedToShopEmail < ActiveRecord::Migration
  def change
    add_column :shop_emails, :bounced, :boolean
  end
end
