class AddCosmeticNailToItem < ActiveRecord::Migration
  def change
    add_column :items, :cosmetic_nail, :boolean
    add_column :items, :cosmetic_nail_type, :string
    add_column :items, :cosmetic_nail_color, :string
    add_column :items, :cosmetic_perfume_aroma, :string, array: true
    add_column :items, :cosmetic_professional, :boolean
  end
end
