class RenameCosmeticPartType < ActiveRecord::Migration
  def change
    rename_column :items, :cosmetic_part_type, :cosmetic_skin_part
  end
end
