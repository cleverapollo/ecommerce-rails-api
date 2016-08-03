class AddBatchToWebPushDigestMessage < ActiveRecord::Migration
  def change
    add_column :web_push_digest_messages, :web_push_digest_batch_id, :integer, limit: 8, null: false
  end
end
