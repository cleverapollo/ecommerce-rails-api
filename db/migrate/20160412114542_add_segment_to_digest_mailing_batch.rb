class AddSegmentToDigestMailingBatch < ActiveRecord::Migration
  def change
    add_column :digest_mailing_batches, :activity_segment, :integer
  end
end
