class ChangeItemUrlsToText < ActiveRecord::Migration
  def change
    change_column :items, :url, :text
    change_column :items, :image_url, :text
  end
end
