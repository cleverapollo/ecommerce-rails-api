class AddSegmentToSubscriptionSettings < ActiveRecord::Migration
  def change
    add_column :subscriptions_settings, :segment_id, :integer
  end
end
