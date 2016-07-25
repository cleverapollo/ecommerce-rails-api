class RenameMessageToSubjectForWebPush < ActiveRecord::Migration
  def change
    rename_column :web_push_triggers, :message, :subject
  end
end
