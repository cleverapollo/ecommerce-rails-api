class CreateSearchSettings < ActiveRecord::Migration
  def change
    create_table :search_settings do |t|
      t.integer :shop_id
      t.string :landing_page
      t.string :filter_position, default: 'none'

      t.timestamps null: false
    end
    add_index :search_settings, :shop_id, unique: true
  end
end
