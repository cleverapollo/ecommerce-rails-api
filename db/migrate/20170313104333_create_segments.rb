class CreateSegments < ShardMigration
  def up
    enable_extension 'intarray'

    add_column :clients, :segment_ids, :integer, array: true
    execute 'CREATE INDEX index_clients_on_shop_id_and_segment_ids ON clients USING gin (shop_id, segment_ids gin__int_ops) WHERE segment_ids IS NOT NULL'
    remove_column :clients, :activity_segment

    remove_column :digest_mailings, :activity_segment
    add_column :digest_mailings, :segment_id, :integer

    remove_column :digest_mailing_batches, :activity_segment
    add_column :digest_mailing_batches, :segment_id, :integer

    # Remove incorrect index
    remove_index :clients, name: 'index_clients_on_triggers_enabled_and_shop_id'
    remove_index :clients, name: 'index_clients_on_digests_enabled_and_shop_id'
    remove_index :clients, name: 'shops_users_shop_id_id_idx'

    # Create correct index for triggers and digests
    add_index :clients, :shop_id, where: 'email IS NOT NULL AND triggers_enabled IS true', name: 'index_clients_on_shop_id_and_triggers_enabled'
    add_index :clients, :shop_id, where: 'email IS NOT NULL AND digests_enabled IS true', name: 'index_clients_on_shop_id_and_digests_enabled'
  end

  def down
    remove_column :clients, :segment_ids

    add_column :clients, :activity_segment, :integer

    add_column :digest_mailings, :activity_segment, :integer
    remove_column :digest_mailings, :segment_id

    add_column :digest_mailing_batches, :activity_segment, :integer
    remove_column :digest_mailing_batches, :segment_id

    add_index :clients, [:triggers_enabled, :shop_id]
    add_index :clients, [:digests_enabled, :shop_id], name: 'index_clients_on_digests_enabled_and_shop_id', using: :btree
    add_index :clients, [:shop_id, :id], name: 'shops_users_shop_id_id_idx', where: '((email IS NOT NULL) AND (digests_enabled = true))', using: :btree
    remove_index :clients, name: 'index_clients_on_shop_id_and_triggers_enabled'
    remove_index :clients, name: 'index_clients_on_shop_id_and_digests_enabled'

    disable_extension 'intarray'
  end
end
