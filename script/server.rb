require 'brb'
require 'yaml'

EM.threadpool_size = 100

Dir.glob("#{ENV['MAHOUT_DIR']}/libexec/*.jar").each { |d| require d }
Dir.glob("#{ENV['REES46_LIBRARIES_DIR']}/libexec/*.jar").each { |d| require d }

ReloadDataModel = org.apache.mahout.cf.taste.impl.model.jdbc.ReloadFromJDBCDataModel
PgDataModel = org.apache.mahout.cf.taste.impl.model.jdbc.PostgreSQLJDBCDataModel
DataSource = org.postgresql.ds.PGSimpleDataSource
Similarity = org.apache.mahout.cf.taste.impl.similarity.UncenteredCosineSimilarity
Neighborhood = org.apache.mahout.cf.taste.impl.neighborhood.NearestNUserNeighborhood
Recommender = org.apache.mahout.cf.taste.impl.recommender.GenericUserBasedRecommender

class CommonDriver
  def self.get_data_source
    db_config = YAML.load_file(File.expand_path('../../config/database.yml', __FILE__))[ENV['RAILS_ENV']]

    ds = DataSource.new
    ds.setServerName(db_config['host'])
    ds.setUser(db_config['username'])
    ds.setPassword(db_config['password'])
    ds.setDatabaseName(db_config['database'])
    ds.setPortNumber(db_config['port'])

    ds
  end
end

class MahoutService
  def initialize
    @model = ReloadDataModel.new(PgDataModel.new(CommonDriver.get_data_source, 'actions', 'user_id', 'item_id', 'rating', 'timestamp'))
    @similarity = Similarity.new(@model)
    @neighborhood = Neighborhood.new(10, @similarity, @model)
    @recommender = Recommender.new(@model, @neighborhood, @similarity)
  end

  def recommend(user_id)
    res = @recommender.recommend(user_id, 10)
    return res.to_s
  end
end

class MahoutServiceGateway
  REFRESH_TIME = 100

  def initialize
    @mahout_service = nil
  end

  def initialize_service
    @mahout_service = MahoutService.new
  end

  def recommend(user_id)
    puts "Asked for recommendations for #{user_id}"
    if @mahout_service
      @mahout_service.recommend(user_id)
    else
      'not initialized'
    end
  end

  def refresh_scheduled
    puts 'Refresh started...'

    new_mahout_service = MahoutService.new
    @mahout_service = new_mahout_service

    puts 'Refresh finished!'

    EM.add_timer(REFRESH_TIME) { EM.defer { self.refresh_scheduled } }
  end
end

service_gateway = MahoutServiceGateway.new

EM::run do
  BrB::Service.start_service(object: service_gateway, host: 'localhost', port: 5555)

  EM.defer { service_gateway.initialize_service }

  EM.add_timer(MahoutServiceGateway::REFRESH_TIME) { EM.defer { service_gateway.refresh_scheduled } }
end
