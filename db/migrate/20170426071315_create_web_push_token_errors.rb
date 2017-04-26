class CreateWebPushTokenErrors < ShardMigration
  def change
    create_table :web_push_token_errors do |t|
      t.integer :client_id, limit: 8
      t.integer :shop_id
      t.jsonb :message

      t.timestamps null: false
    end

    add_index :web_push_digest_messages, [:shop_id, :web_push_digest_id], where: 'unsubscribed = false', name: 'index_web_push_digest_msg_on_shop_id_and_digest_id_unsubscribed'
  end
end
