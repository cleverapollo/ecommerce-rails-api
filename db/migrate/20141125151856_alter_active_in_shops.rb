class AlterActiveInShops < ActiveRecord::Migration
  def change
    change_column :shops, :active, :boolean, default: true, null: false
  end
end
