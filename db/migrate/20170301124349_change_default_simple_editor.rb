class ChangeDefaultSimpleEditor < ActiveRecord::Migration
  def change
    change_column_default :trigger_mailings, :simple_editor, true
  end
end
