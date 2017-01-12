class AddSettingsTypeToShopTheme < ActiveRecord::Migration
  def change
    add_column :shop_themes, :source_type, :string
  end
end
