# Define shard ID
raise 'ERROR: environment variable REES46_SHARD not set' unless ENV['REES46_SHARD'].present?
SHARD_ID = ENV['REES46_SHARD']