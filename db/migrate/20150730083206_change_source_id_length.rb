class ChangeSourceIdLength < ActiveRecord::Migration
  def change
    change_column :orders, :source_id, :integer, limit: 8
  end
end
