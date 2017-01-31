class AddImageDownloadingErrorToItems < ActiveRecord::Migration
  def change
    add_column :items, :image_downloading_error, :string
  end
end
