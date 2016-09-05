class RemoveOldTemplates < ActiveRecord::Migration
  def change
    remove_column :trigger_mailings, :template
    remove_column :trigger_mailings, :item_template
    remove_column :trigger_mailings, :source_item_template
    remove_column :digest_mailings, :template
    remove_column :digest_mailings, :item_template
  end
end
