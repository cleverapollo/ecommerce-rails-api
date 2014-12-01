class CreateTriggerMails < ActiveRecord::Migration
  def change
    create_table :trigger_mails do |t|
      t.references :shop, null: false
      t.references :subscription, null: false
      t.string :trigger_code, null: false
      t.text :trigger_data, null: false
      t.uuid :code, null: false, default: 'uuid_generate_v4()'
      t.boolean :clicked, null: false, default: false

      t.timestamps
    end

    add_index :trigger_mails, :code, unique: true
  end
end
