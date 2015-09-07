class AddCosmeticsFieldsToItems < ActiveRecord::Migration
  def change
    add_column :items, :hypoallergenic, :boolean
    add_column :items, :part_type, :string
    add_column :items, :skin_type, :string
    add_column :items, :condition, :string
    add_column :items, :volume, :integer
  end
end
