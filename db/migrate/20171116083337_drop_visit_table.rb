class DropVisitTable < ActiveRecord::Migration
  def change
    drop_table :visits
  end
end
