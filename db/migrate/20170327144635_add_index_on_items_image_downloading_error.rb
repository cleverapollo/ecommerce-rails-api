class AddIndexOnItemsImageDownloadingError < ActiveRecord::Migration
  def change
    add_index :items, [:shop_id, :image_downloading_error], where: 'image_downloading_error IS NOT NULL'
  end
end
