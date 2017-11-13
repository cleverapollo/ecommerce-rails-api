class AddSearchTypeToSearchSettings < ActiveRecord::Migration
  def change
    add_column :search_settings, :search_type, :string, null: false, default: 'full'
  end
end
