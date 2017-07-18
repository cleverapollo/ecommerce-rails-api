class AddSourceUserToRtbJob < ActiveRecord::Migration
  def change
    add_column :rtb_jobs, :source_user_id, :integer, limit: 8
    add_index "rtb_jobs", ["active", "date", "source_user_id"], where: "(active IS TRUE)"
    add_index "rtb_jobs", ["shop_id", "source_user_id"]
  end
end
