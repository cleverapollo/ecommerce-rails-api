class ChangeDigestMailingBatches < ActiveRecord::Migration
  def change
    change_column :digest_mailing_batches, :end_id, :integer
    add_column :digest_mailing_batches, :start_id, :integer
    add_column :digest_mailing_batches, :test_email, :string
  end
end
