class RemoveBrandFromActions < ActiveRecord::Migration
  def change
    remove_column :actions, :brand
  end
end
