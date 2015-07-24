namespace :db do
  namespace :schema do
    desc 'Dump additional database schema'
    task :dump => [:environment, :load_config] do
      filename = "#{Rails.root}/db/shards_schema.rb"
      File.open(filename, 'w:utf-8') do |file|
        ActiveRecord::Base.establish_connection(MASTER_DB)
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end
  end

  namespace :test do
    # desc 'Purge and load foo_test schema'
    task :load_schema do
      # like db:test:purge
      ActiveRecord::Base.connection.recreate_database(MASTER_DB['database'], mysql_creation_options(MASTER_DB))
      # like db:test:load_schema
      ActiveRecord::Base.establish_connection(MASTER_DB)
      ActiveRecord::Schema.verbose = false
      load("#{Rails.root}/db/shards_schema.rb")
    end
  end
end