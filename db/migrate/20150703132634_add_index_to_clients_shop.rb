class AddIndexToClientsShop < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE INDEX idx_clients_shop_id_last_trigger_email_nulls_first ON clients (shop_id, last_trigger_mail_sent_at ASC NULLS FIRST) where triggers_enabled = 't' and email is not null;
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX idx_clients_shop_id_last_trigger_email_nulls_first;
    SQL
  end
end
