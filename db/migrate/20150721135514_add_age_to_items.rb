class AddAgeToItems < ActiveRecord::Migration
  def change
    add_column :items, :age_min, :float
    add_column :items, :age_max, :float
  end
end
