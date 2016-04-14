class AddTemplateTypeToMailingsSettings < ActiveRecord::Migration
  def change
    add_column :mailings_settings, :template_type, :integer, default: 0
  end
end
