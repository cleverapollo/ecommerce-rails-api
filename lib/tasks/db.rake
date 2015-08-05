namespace :db do

  namespace :test do
    task :prepare => [:environment, :load_config] do
      ActiveRecord::Base.establish_connection(MASTER_DB)
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE users")
    end

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
    task :create => [:environment, :load_config] do
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{MASTER_DB['database']}")
    end

    desc 'Prepare config for codeship'
    task :codeship_prepare do
      config = YAML.load(ERB.new(File.read("config/shards.yml.example")).result).to_yaml
      filename = "#{Rails.root}/config/shards.yml"
      File.open(filename, 'w:utf-8') do |file|
        file.write(config)
      end
    end

  end
end