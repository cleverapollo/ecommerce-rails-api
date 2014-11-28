class MailingBatchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform(shop_id, mailing_id, start_id, end_id)
  end
end
