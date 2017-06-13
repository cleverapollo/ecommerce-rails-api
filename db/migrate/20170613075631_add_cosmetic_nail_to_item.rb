class AddCosmeticNailToItem < ActiveRecord::Migration
  def change
    add_column :items, :cosmetic_nail_type, :string
    add_column :items, :cosmetic_perfume_aroma, :string
    add_column :items, :cosmetic_professional, :boolean
  end
end
