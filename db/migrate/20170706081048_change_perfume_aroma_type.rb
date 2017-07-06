class ChangePerfumeAromaType < ActiveRecord::Migration
  def change
    remove_column :items, :cosmetic_perfume_aroma
    add_column :items, :cosmetic_perfume_family, :string
    add_column :items, :cosmetic_perfume_aroma, :string
  end
end
