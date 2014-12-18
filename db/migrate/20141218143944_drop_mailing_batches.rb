class DropMailingBatches < ActiveRecord::Migration
  def change
    drop_table :mailing_batches
  end
end
