class AddEmailToUserShopRelations < ActiveRecord::Migration
  def change
    add_column :user_shop_relations, :email, :string
  end
end
