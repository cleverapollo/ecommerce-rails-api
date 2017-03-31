class UserMergeRemnantsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform(master_id, slave_id)
    UserMerger.merge_remnants(master_id, slave_id)
  end
end