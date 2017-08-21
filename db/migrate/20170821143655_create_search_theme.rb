class CreateSearchTheme < ActiveRecord::Migration
  def change
    add_column :search_settings, :theme_id, :integer, limit: 8
    add_column :search_settings, :theme_type, :string
    add_index :search_settings, [:shop_id, :theme_id, :theme_type], name: 'index_search_settings_theme'
  end
end
