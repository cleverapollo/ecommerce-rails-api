class AddMailchimpFieldsToDigestMailing < ActiveRecord::Migration
  def change
    add_column :digest_mailings, :mailchimp_campaign_id, :string
    add_column :digest_mailings, :mailchimp_list_id, :string
  end
end
