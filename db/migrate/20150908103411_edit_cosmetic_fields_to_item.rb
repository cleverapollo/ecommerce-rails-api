class EditCosmeticFieldsToItem < ActiveRecord::Migration
  def change
    remove_column :items, :part_type
    remove_column :items, :skin_type
    remove_column :items, :condition

    add_column :items, :part_type, :string, array:true
    add_column :items, :skin_type, :string, array:true
    add_column :items, :condition, :string, array:true
  end
end
