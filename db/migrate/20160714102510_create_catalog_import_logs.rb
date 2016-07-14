class CreateCatalogImportLogs < ActiveRecord::Migration
  def change
    create_table :catalog_import_logs do |t|
      t.integer :shop_id
      t.integer :filesize, default: 0, null: false
      t.integer :total, default: 0, null: false
      t.integer :available, default: 0, null: false
      t.integer :widgetable, default: 0, null: false
      t.integer :categories, default: 0, null: false
      t.string :message
      t.boolean :success, default: false
      t.timestamps null: false
    end
  end
end
