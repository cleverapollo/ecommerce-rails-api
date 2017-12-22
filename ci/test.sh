bundle install
export RAILS_ENV=test
cp config/database.yml.example config/database.yml
sed -i "s|5432|5435|" "config/database.yml"
# psql -c 'create database master_database;'
psql -p 5435 -c 'create database rees46_clickhouse_test;'
cp config/secrets.yml.example config/secrets.yml
