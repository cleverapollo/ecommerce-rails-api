class AddDowncaseBrandToAdvertiser < ActiveRecord::Migration
  def change
    add_column :advertisers, :downcase_brand, :string
  end
end
