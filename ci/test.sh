
function test_postgresql {
  pg_isready -h postgres -U rails
}


count=0
# Chain tests together by using &&
until ( test_postgresql )
do
  ((count++))
  if [ ${count} -gt 50 ]
  then
    echo "Services didn't become ready in time"
    exit 1
  fi
  sleep 0.1
done


bundle install
export RAILS_ENV=test
export REES46_SHARD=01
cp config/database.yml.example config/database.yml
sed -i "s|localhost|postgres|" "config/database.yml"
echo "*:5432:*:rails:rails"  > ~/.pgpass
ls -la ~/.pgpass
echo ~/.pgpass
chmod 0600 ~/.pgpass
echo 'Creating database rees46_clickhouse_test'
psql -h postgres -U rails rees46_test -c 'create database rees46_clickhouse_test;'

cp config/secrets.yml.example config/secrets.yml
bin/testing
