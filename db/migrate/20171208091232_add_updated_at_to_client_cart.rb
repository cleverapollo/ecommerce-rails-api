class AddUpdatedAtToClientCart < ActiveRecord::Migration
  def change
    add_column :client_carts, :updated_at, :datetime
  end
end
