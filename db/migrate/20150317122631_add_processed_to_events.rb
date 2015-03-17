class AddProcessedToEvents < ActiveRecord::Migration
  def change
    add_column :events, :processed, :boolean, default: false, null: false

    Event.reset_column_information

    Event.update_all(processed: true)
  end
end
