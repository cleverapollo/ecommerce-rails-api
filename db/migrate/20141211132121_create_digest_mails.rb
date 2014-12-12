class CreateDigestMails < ActiveRecord::Migration
  def change
    create_table :digest_mails do |t|
      t.references :shop, null: false
      t.references :audience, null: false
      t.references :digest_mailing, null: false
      t.references :digest_mailing_batch, null: false
      t.uuid :code, null: false, default: 'uuid_generate_v4()'
      t.boolean :clicked, null: false, default: false
      t.boolean :opened, null: false, default: false

      t.timestamps
    end

    add_index :digest_mails, :code, unique: true
  end
end
