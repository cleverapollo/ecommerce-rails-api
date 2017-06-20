class AddSegmentDsToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :segment_ds, :string
  end
end
