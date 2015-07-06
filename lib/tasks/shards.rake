# db_conf = YAML::load(File.open(File.join(Rails.root,'config','shards.yml')))
# API_DB_00 = db_conf[Rails.env]['api_db_00']
# API_DB_01 = db_conf[Rails.env]['api_db_01']
#
#
# desc 'Manage migrations on shards databases'
#
# namespace :shards do
#
#   task :migrate do
#     Rake::Task['shards:migrate_db_00'].invoke
#   end
#
#   task :migrate_db_00 do
#     ActiveRecord::Base.establish_connection API_DB_00
#     ActiveRecord::Migrator.migrate('db/migrate/shards/')
#   end
#
#
#   task :rollback do
#     Rake::Task['shards:rollback_db_00'].invoke
#   end
#
#   task :rollback_db_00 do
#     ActiveRecord::Base.establish_connection API_DB_00
#     ActiveRecord::Migrator.rollback('db/migrate/shards/')
#   end
#
#
# end
