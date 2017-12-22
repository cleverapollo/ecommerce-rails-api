bundle install
export RAILS_ENV=test
cp config/database.yml.example config/database.yml
#sed -i "s|localhost|database|" "config/database.yml"
# psql -c 'create database master_database;'
#Wait for pg to come up
function test_postgresql {
  pg_isready -h postgres
}

count=0
# Chain tests together by using &&
until ( test_postgresql)
do
  ((count++))
  if [ ${count} -gt 50 ]
  then
    echo "Services didn't become ready in time"
    exit 1
  fi
  sleep 1
done

cp config/secrets.yml.example config/secrets.yml
bin/testing
