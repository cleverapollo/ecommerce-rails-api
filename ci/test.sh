bundle install
export RAILS_ENV=test
cp config/database.yml.example config/database.yml
#sed -i "s|localhost|database|" "config/database.yml"
# psql -c 'create database master_database;'
#Wait for pg to come up
sleep 10

cp config/secrets.yml.example config/secrets.yml
bin/testing
