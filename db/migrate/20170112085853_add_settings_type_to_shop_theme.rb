class AddSettingsTypeToShopTheme < ActiveRecord::Migration
  def change
    add_column :shop_themes, :source_type, :string, default: 'SubscriptionsSettings'
    change_column_default :shop_themes, :source_type, nil
  end
end
