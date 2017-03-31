class UserMergeRemnantsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform(master_id, slave_id)
    STDOUT.write " merge master: #{master_id} from slave #{slave_id}\n"
    UserMerger.merge_remnants(master_id, slave_id)
  end
end