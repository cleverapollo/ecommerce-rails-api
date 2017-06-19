class AddSegmentsToInteraction < ActiveRecord::Migration
  def change
    add_column :interactions, :segments, :string, array: true
    add_column :client_carts, :segments, :string, array: true
    add_column :orders, :segments, :string, array: true
  end
end
