class AddRealtyToItem < ActiveRecord::Migration
  def change
    add_column :items, :is_realty, :boolean
    add_column :items, :realty_type, :string
    add_column :items, :realty_space_min, :float
    add_column :items, :realty_space_max, :float
    add_column :items, :realty_space_final, :float
  end
end
