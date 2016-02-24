class AddGetResponseIntegration < ActiveRecord::Migration
  def change
    add_column :mailings_settings, :mailing_service, :integer, default: 0
    add_column :mailings_settings, :getresponse_api_key, :string
    add_column :mailings_settings, :getresponse_api_url, :string
  end
end
