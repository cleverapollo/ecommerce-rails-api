db_conf = YAML::load(File.open(File.join(Rails.root,'config','shards.yml')))
MASTER_DB = db_conf[Rails.env]['master']
API_DB_00 = db_conf[Rails.env]['api_db_00']
API_DB_01 = db_conf[Rails.env]['api_db_01']
