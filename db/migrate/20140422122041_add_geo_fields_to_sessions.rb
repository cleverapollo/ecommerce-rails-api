class AddGeoFieldsToSessions < ActiveRecord::Migration
  def change
    add_column :sessions, :city, :string
    add_column :sessions, :country, :string
    add_column :sessions, :language, :string
  end
end
