class AddBouncedToDigestMails < ActiveRecord::Migration
  def change
    add_column :digest_mails, :bounced, :boolean, default: false, null: false
  end
end
