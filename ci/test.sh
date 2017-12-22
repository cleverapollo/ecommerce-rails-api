bundle install
export RAILS_ENV=test
cp config/database.yml.example config/database.yml
#sed -i "s|localhost|database|" "config/database.yml"
# psql -c 'create database master_database;'
psql -p 5432 -h postgres -c 'create database rees46_clickhouse_test;'
cp config/secrets.yml.example config/secrets.yml
