class CreateShopEmails < ActiveRecord::Migration
  def up
    create_table :shop_emails do |t|
      t.references :shop, index: true, null: false
      t.uuid :code, default: "uuid_generate_v4()"
      t.string :email, null: false
      t.boolean :email_confirmed
      t.boolean :digests_enabled, null: false, default: true
      t.boolean :triggers_enabled, null: false, default: true
      t.boolean :digest_opened
      t.datetime :last_trigger_mail_sent_at
      t.integer :segment_ids, array: true

      t.timestamps null: false
    end
    execute('ALTER TABLE shop_emails ALTER COLUMN created_at SET DEFAULT now(), ALTER COLUMN updated_at SET DEFAULT now()')

    add_index :shop_emails, :code, unique: true
    add_index :shop_emails, [:email, :shop_id], unique: true
    add_index :shop_emails, [:shop_id, :email_confirmed, :id], name: 'index_shop_emails_on_shop_id_and_digests_enabled', where: 'digests_enabled = true'
    add_index :shop_emails, [:shop_id, :email_confirmed, :id], name: 'index_shop_emails_on_shop_id_and_triggers_enabled', where: 'triggers_enabled = true'
    add_index :shop_emails, [:shop_id, :last_trigger_mail_sent_at], where: 'last_trigger_mail_sent_at IS NOT NULL AND triggers_enabled = true'
    add_index :shop_emails, [:shop_id, :segment_ids], where: 'segment_ids IS NOT NULL', using: :gin

    add_column :digest_mails, :shop_email_id, :integer
    change_column_null :digest_mails, :client_id, true
    add_index :digest_mails, :shop_email_id, where: 'shop_email_id IS NOT NULL'
  end

  def down
    drop_table :shop_emails
    remove_column :digest_mails, :shop_email_id
  end
end
