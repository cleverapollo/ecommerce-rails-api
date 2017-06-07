class AddVideoUrlToReputations < ActiveRecord::Migration
  def change
    add_column :reputations, :video_url, :string
    add_column :reputations, :images, :integer, limit: 8, array: true, default: []
  end
end
