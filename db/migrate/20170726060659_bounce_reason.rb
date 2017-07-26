class BounceReason < ActiveRecord::Migration
  def change
    add_column :digest_mails, :bounce_reason, :integer, limit: 1
    add_column :trigger_mails, :bounce_reason, :integer, limit: 1
  end
end
