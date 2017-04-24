class AddActionsToWebPushDigest < ActiveRecord::Migration
  def change
    add_column :web_push_digests, :actions, :jsonb
    add_column :web_push_digests, :additional_image, :string
  end
end
