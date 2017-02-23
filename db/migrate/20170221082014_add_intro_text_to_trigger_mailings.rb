class AddIntroTextToTriggerMailings < ActiveRecord::Migration
  def change
    add_column :trigger_mailings, :intro_text, :string
  end
end
