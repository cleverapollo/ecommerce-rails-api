class AddImageSizeToTriggerMailing < ActiveRecord::Migration
  def change
    add_column :trigger_mailings, :image_width, :integer, default: 180
    add_column :trigger_mailings, :image_height, :integer, default: 180
  end
end
