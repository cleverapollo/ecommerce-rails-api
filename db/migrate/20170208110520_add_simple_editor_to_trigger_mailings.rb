class AddSimpleEditorToTriggerMailings < ActiveRecord::Migration
  def change
    add_column :trigger_mailings, :simple_editor, :boolean, null: false, default: false
  end
end
