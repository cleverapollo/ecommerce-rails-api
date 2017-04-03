class UserMergeRemnantsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform(master_id, slave_id)
    UserMerger.merge_remnants(master_id, slave_id)

  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end
end