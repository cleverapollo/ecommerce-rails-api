class FuckupWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform
    raise StandardError, 'This should be reported'
  end
end
