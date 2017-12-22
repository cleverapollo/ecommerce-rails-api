bundle install
export RAILS_ENV=test
export REES46_SHARD=01
cp config/database.yml.example config/database.yml
sed -i "s|localhost|postgres|" "config/database.yml"
# psql -c 'create database master_database;'
#Wait for pg to come up
sleep 10
echo *:5432:*:rails:rails  > ~/.pgpass
ls -la ~/.pgpass
echo ~/.pgpass
chmod 0600 ~/.pgpass

cp config/secrets.yml.example config/secrets.yml
bin/testing
