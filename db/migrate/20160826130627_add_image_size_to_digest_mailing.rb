class AddImageSizeToDigestMailing < ActiveRecord::Migration
  def change
    add_column :digest_mailings, :image_width, :integer, default: 180
    add_column :digest_mailings, :image_height, :integer, default: 180
  end
end
