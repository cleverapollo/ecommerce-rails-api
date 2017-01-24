class RemoveLogoFromMailingsSettings < ActiveRecord::Migration
  def change
    remove_attachment :mailings_settings, :logo
  end
end
