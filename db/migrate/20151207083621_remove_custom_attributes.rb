class RemoveCustomAttributes < ActiveRecord::Migration
  def change
    remove_column :items, :custom_attributes
    remove_column :items, :tags
  end
end
