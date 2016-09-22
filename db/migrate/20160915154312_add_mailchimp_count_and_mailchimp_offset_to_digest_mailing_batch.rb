class AddMailchimpCountAndMailchimpOffsetToDigestMailingBatch < ActiveRecord::Migration
  def change
    add_column :digest_mailing_batches, :mailchimp_count, :integer
    add_column :digest_mailing_batches, :mailchimp_offset, :integer
  end
end
