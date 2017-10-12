class ElasticReindexWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform(shop_id)
    Retailer::Products::ElasticSync.new(Shop.find(shop_id)).perform
  end
end
