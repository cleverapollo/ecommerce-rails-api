class AddNewYmlFieldsToItem < ActiveRecord::Migration
  def change
    add_column :items, :type_prefix, :string
    add_column :items, :vendor_code, :string
    add_column :items, :model, :string
    add_column :items, :gender, :string, limit:1
    add_column :items, :wear_type, :string, limit:20
    add_column :items, :feature, :string, limit:20
    add_column :items, :sizes, :string, array: true, default: '{}'
  end
end
