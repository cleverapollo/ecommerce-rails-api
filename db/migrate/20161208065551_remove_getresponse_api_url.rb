class RemoveGetresponseApiUrl < ActiveRecord::Migration
  def change
    remove_column :mailings_settings, :getresponse_api_url
  end
end
