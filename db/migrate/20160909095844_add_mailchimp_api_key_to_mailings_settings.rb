class AddMailchimpApiKeyToMailingsSettings < ActiveRecord::Migration
  def change
    add_column :mailings_settings, :mailchimp_api_key, :string
  end
end
