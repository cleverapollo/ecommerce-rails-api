class AddClientIdsToDigestBatch < ActiveRecord::Migration
  def change
    add_column :web_push_digest_batches, :client_ids, :integer, limit: 8, array: true
    add_column :digest_mailing_batches, :client_ids, :integer, limit: 8, array: true
  end
end
