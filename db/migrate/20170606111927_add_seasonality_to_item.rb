class AddSeasonalityToItem < ActiveRecord::Migration
  def change
    add_column :items, :seasonality, :integer, array: true
  end
end
