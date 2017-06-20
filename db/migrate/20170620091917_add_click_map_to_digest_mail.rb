class AddClickMapToDigestMail < ActiveRecord::Migration
  def change
    add_column :digest_mails, :click_map, :integer, array: true
  end
end
