class AddSocialIdToClient < ActiveRecord::Migration
  def change
    add_column :clients, :fb_id, :integer, limit: 8
    add_column :clients, :vk_id, :integer, limit: 8
  end
end
