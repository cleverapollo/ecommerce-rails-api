class ChangeDigestMails < ActiveRecord::Migration
  def change
    DigestMail.delete_all
    remove_column :digest_mails, :audience_id, :integer
    add_column :digest_mails, :shops_user_id, :integer, null: false
    add_index :digest_mails, :shops_user_id
  end
end
