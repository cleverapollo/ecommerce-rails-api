class ChangeDefaultTemplate < ActiveRecord::Migration
  def change
    change_column :mailings_settings, :template_type, :integer, default: 1
  end
end
