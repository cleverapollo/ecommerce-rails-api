class AddChildParametersToItem < ActiveRecord::Migration
  def change
    rename_column :items, :age_min, :child_age_min
    rename_column :items, :age_max, :child_age_max
    add_column :items, :child_gender, :string, limit: 1
    add_column :items, :child_type, :string
  end
end
