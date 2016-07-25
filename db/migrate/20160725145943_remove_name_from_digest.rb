class RemoveNameFromDigest < ActiveRecord::Migration
  def change
    remove_column :web_push_digests, :name
  end
end
