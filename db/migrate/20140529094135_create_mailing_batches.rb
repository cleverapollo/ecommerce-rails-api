class CreateMailingBatches < ActiveRecord::Migration
  def change
    create_table :mailing_batches do |t|
      t.integer :mailing_id, null: false
      t.text :users, null: false
      t.string :state, default: 'enqueued', null: false
      t.text :statistics, null: false
      t.text :failed, null: false
      t.timestamps
    end

    add_index :mailing_batches, :mailing_id
  end
end
