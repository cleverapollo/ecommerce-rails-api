class ChangeTypeExceptionMessage < ActiveRecord::Migration
  def change
    change_column :client_errors, :exception_message, :text
  end
end
