class AddTextTemplateToTriggerMailing < ActiveRecord::Migration
  def change
    rename_column :digest_mailings, :text, :text_template
    add_column :trigger_mailings, :text_template, :text, null: false, default: ''
  end
end
