class CreateTriggerMailingQueues < ActiveRecord::Migration
  def change
    create_table :trigger_mailing_queues, id: :bigserial do |t|
      t.integer :shop_id
      t.integer :user_id, limit: 8
      t.string :email
      t.string :trigger_type
      t.datetime :triggered_at
      t.string :recommended_items, array: true
      t.string :source_items, array: true
      t.string :trigger_mail_code
    end
    add_index :trigger_mailing_queues, :shop_id
    add_index :trigger_mailing_queues, :triggered_at
  end
end
