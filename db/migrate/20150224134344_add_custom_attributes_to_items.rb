class AddCustomAttributesToItems < ActiveRecord::Migration
  def change
    add_column :items, :custom_attributes, :jsonb, default: '{}', null: false
    add_index :items, :custom_attributes, using: :gin
  end
end
