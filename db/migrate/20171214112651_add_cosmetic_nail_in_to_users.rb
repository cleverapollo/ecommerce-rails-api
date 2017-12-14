class AddCosmeticNailInToUsers < ActiveRecord::Migration
  def change
    add_column :users, :cosmetic_nail, :jsonb
  end
end
