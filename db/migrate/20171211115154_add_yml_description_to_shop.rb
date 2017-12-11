class AddYmlDescriptionToShop < ActiveRecord::Migration
  def change
    add_column :shops, :yml_description, :boolean, null: false, default: false
  end
end
