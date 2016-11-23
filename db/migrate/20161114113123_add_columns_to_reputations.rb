class AddColumnsToReputations < ActiveRecord::Migration
  def change
    add_column :reputations, :status, :integer, null: false, default: 0
    add_column :reputations, :client_id, :integer, limit: 8, index: true
  end
end
