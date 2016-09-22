class AddMailchimpCampaignIdToTriggerMailings < ActiveRecord::Migration
  def change
    add_column :trigger_mailings, :mailchimp_campaign_id, :string
  end
end
