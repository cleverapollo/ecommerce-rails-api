class AddBrandToAdvertiser < ActiveRecord::Migration
  def change
    add_column :advertisers, :brand, :string
  end
end
