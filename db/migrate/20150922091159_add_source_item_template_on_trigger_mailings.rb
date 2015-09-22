class AddSourceItemTemplateOnTriggerMailings < ActiveRecord::Migration
  def change
    add_column :trigger_mailings, :source_item_template, :text
  end
end
