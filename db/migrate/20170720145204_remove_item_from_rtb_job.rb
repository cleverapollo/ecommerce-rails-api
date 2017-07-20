class RemoveItemFromRtbJob < ActiveRecord::Migration
  def change
    remove_column :rtb_jobs, :item_id
    remove_column :rtb_jobs, :image
    remove_column :rtb_jobs, :price
    remove_column :rtb_jobs, :name
  end
end
