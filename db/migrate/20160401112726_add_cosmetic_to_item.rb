class AddCosmeticToItem < ActiveRecord::Migration
  def change
    change_table :items do |t|
      t.string :cosmetic_gender, limit: 1
      t.boolean :cosmetic_hypoallergenic
      t.string :cosmetic_part_type, array: true
      t.string :cosmetic_skin_type, array: true
      t.string :cosmetic_skin_condition, array: true
      t.string :cosmetic_hair_type, array: true
      t.string :cosmetic_hair_condition, array: true
      t.jsonb :cosmetic_volume
      t.boolean :cosmetic_periodic
    end
  end
end
