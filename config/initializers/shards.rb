# Load connect info for master database
db_conf = YAML::load(File.open(File.join(Rails.root,'config','shards.yml')))
MASTER_DB = db_conf[Rails.env]['master']

# Define shard ID
SHARD_ID = ENV['REES46_SHARD'] || '00'