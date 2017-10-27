class AddAudienceSourceToClients < ActiveRecord::Migration
  def change
    add_column :clients, :audience_sources, :string
    add_column :clients, :external_audience_sources, :text
  end
end
