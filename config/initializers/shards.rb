db_conf = YAML::load(File.open(File.join(Rails.root,'config','shards.yml')))
MASTER_DB = db_conf[Rails.env]['master']
