class AddPictureToWebPush < ActiveRecord::Migration
  def change
    add_attachment :web_push_digests, :picture
  end
end
