class AddSegmentIdsInToDigestMailings < ActiveRecord::Migration
  def change
    add_column :digest_mailings, :segment_ids, :integer, array: true
    add_column :digest_mailing_batches, :segment_ids, :integer, array: true

    add_column :digest_mailings, :exclude_segment_ids, :integer, array: true
    add_column :digest_mailing_batches, :exclude_segment_ids, :integer, array: true

    DigestMailing.where.not(segment_id: nil).find_each(batch_size: 1000) do |digest_mailing|
      digest_mailing.update(segment_ids: [digest_mailing.segment_id])
    end
    DigestMailingBatch.where.not(segment_id: nil).find_each(batch_size: 1000) do |digest_mailing_batch|
      digest_mailing_batch.update(segment_ids: [digest_mailing_batch.segment_id])
    end

  end
end
