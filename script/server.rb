require 'brb'
require 'yaml'
require 'jruby/core_ext'
require 'active_support'

EM.threadpool_size = 100

Dir.glob("#{ENV['MAHOUT_DIR']}/libexec/*.jar").each { |d| require d }
Dir.glob("#{ENV['REES46_LIBRARIES_DIR']}/libexec/*.jar").each { |d| require d }

ReloadDataModel = org.apache.mahout.cf.taste.impl.model.jdbc.ReloadFromJDBCDataModel
PgDataModel = org.apache.mahout.cf.taste.impl.model.jdbc.PostgreSQLJDBCDataModel
DataSource = org.postgresql.ds.PGSimpleDataSource
Similarity = org.apache.mahout.cf.taste.impl.similarity.UncenteredCosineSimilarity
Neighborhood = org.apache.mahout.cf.taste.impl.neighborhood.NearestNUserNeighborhood
Recommender = org.apache.mahout.cf.taste.impl.recommender.GenericUserBasedRecommender
IDRescorer = org.apache.mahout.cf.taste.recommender.IDRescorer
SRecommender = org.apache.mahout.cf.taste.impl.recommender.GenericItemBasedRecommender



# PearsonS
# Generic or SlopeOne

#


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
    @neighborhood = Neighborhood.new(50, @similarity, @model)
    @recommender = Recommender.new(@model, @neighborhood, @similarity)
    @srecommender = SRecommender.new(@model, @similarity)
  end

  def recommend(user_id, params)
    res = if params[:items_to_estimate].is_a?(Array) and params[:items_to_estimate].any?
      recommend_estimate(user_id, params)
    else
      recommend_collaborative(user_id, params)
    end
  end

  def recommend_estimate(user_id, params)
    params[:items_to_estimate].map do |item|
      {
        item: item,
        rating: @srecommender.estimatePreference(user_id, item).to_f
      }
    end.sort{|a, b| b[:rating] <=> a[:rating] }.map{|a| a[:item] }.slice(0, params[:limit])
  end

  def recommend_collaborative(user_id, params)
    res = if params[:items_to_include].any? or params[:items_to_exclude].any?
      @recommender.recommend(user_id, params[:limit], rescorer(params[:items_to_include], params[:items_to_exclude]))
    else
      @recommender.recommend(user_id, params[:limit], nil)
    end
    res.map{|e| e.getItemID }.to_a
  end

  def rescorer(items_to_include = [], items_to_exclude = [])
    r = Class.new do
      cattr_accessor :items_to_include
      cattr_accessor :items_to_exclude
      def self.rescore(l, v)
        return v
      end

      def self.isFiltered(l)
        pass = false
        if self.items_to_include.any?
          pass = !self.items_to_include.include?(l)
        end

        if self.items_to_exclude.any?
          pass = self.items_to_exclude.include?(l)
        end

        return pass
      end
    end

    r.items_to_include = items_to_include
    r.items_to_exclude = items_to_exclude

    r
  end
end

class MahoutServiceGateway
  REFRESH_TIME = 200

  def initialize
    @mahout_service = nil
  end

  def initialize_service
    @mahout_service = MahoutService.new
  end

  def recommend(user_id, params)
    puts "Asked for recommendations for #{user_id} with #{params.inspect}"
    if @mahout_service
      @mahout_service.recommend(user_id, params)
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
