ENV['ENV'] ||= 'development'
db_conf = YAML::load(File.open(File.join(Rails.root,'config','shards.yml')))
API_DB_00 = db_conf[ENV['ENV']]['api_db_00']
API_DB_01 = db_conf[ENV['ENV']]['api_db_01']
