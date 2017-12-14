# todo удалить, когда все разработчики сделают миграции
class DataManager::MoveData

  def self.move(table)
    batch = 1000
    n = 0
    cl = MoveTemp
    cl.table_name = table
    cl.from("#{table}_master as #{table}").select("#{table}.id").find_in_batches(batch_size: batch) do |group|
      ids = group.map(&:id)
      n += ids.size
      cl.transaction do
        ActiveRecord::Base.connection.execute "with moved_rows AS ( delete from #{table}_master where id IN (#{ids.join(',')}) returning * ) insert into #{table} select * from moved_rows ON CONFLICT DO NOTHING;"
      end
      STDOUT.write "\r#{n}"
      sleep(1) if n % 50000 == 0
    end
    STDOUT.write "\n"
  end

  # Копируем только те email которых еще нет в базе магазина
  def self.copy_email(shop)
    i = 0
    shop.clients.with_email.joins('LEFT JOIN shop_emails ON shop_emails.shop_id = clients.shop_id AND shop_emails.email = clients.email').where('shop_emails.email IS NULL').select(:id).find_in_batches do |group|
      ids = group.map(&:id)
      i += ids.size
      puts "\rrow: #{i}"
      ActiveRecord::Base.connection.execute "INSERT INTO shop_emails (shop_id, email, email_confirmed, digests_enabled, triggers_enabled, digest_opened, last_trigger_mail_sent_at, segment_ids) (SELECT shop_id, email, email_confirmed, digests_enabled, triggers_enabled, digest_opened, last_trigger_mail_sent_at, segment_ids FROM clients WHERE id IN (#{ids.join(',')})) ON CONFLICT (shop_id, email) DO NOTHING"
      sleep 0.05
    end
  end

end
