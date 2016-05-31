class AddMailingIndexToDigestMail < ActiveRecord::Migration
  def change
    add_index :digest_mails, :digest_mailing_id
  end
end
