class AddMessageAndUrlToWebPush < ActiveRecord::Migration
  def change
    add_column :web_push_triggers, :message, :string, limit: 125
    add_column :web_push_digests, :message, :string, limit: 125
    add_column :web_push_digests, :url, :string, limit: 4096
  end
end
