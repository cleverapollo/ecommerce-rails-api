class DataManager::MoveData

  def self.move(table)
    batch = 1000
    n = 0
    table.classify.constantize.from("#{table}_master as #{table}").select("#{table}.id").find_in_batches(batch_size: batch) do |group|
      ids = group.map(&:id)
      n += ids.size
      ActiveRecord::Base.connection.execute "with moved_rows AS ( delete from #{table}_master where id IN (#{ids.join(',')}) returning * ) insert into #{table} select * from moved_rows;"
      STDOUT.write "\r#{n}"
      sleep(1) if n % 50000 == 0
    end
    STDOUT.write "\n"
  end

end
