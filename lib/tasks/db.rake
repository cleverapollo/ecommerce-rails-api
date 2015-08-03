namespace :db do

  namespace :test do
    desc 'load tests schema'
    task :load_schema do
      ActiveRecord::Base.establish_connection(MASTER_DB)
      load("#{Rails.root}/db/tests_schema.rb")
    end

    desc 'Dump tests database schema'
    task :dump_schema do
      filename = "#{Rails.root}/db/tests_schema.rb"
      File.open(filename, 'w:utf-8') do |file|
        ActiveRecord::Base.establish_connection(MASTER_DB)
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end

    desc 'Create database'
    task :create do
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{MASTER_DB['database']}")
    end
  end
end