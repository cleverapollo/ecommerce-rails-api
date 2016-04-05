class AddActivitySegmentToDigestMailing < ActiveRecord::Migration
  def change
    add_column :digest_mailings, :activity_segment, :integer
  end
end
