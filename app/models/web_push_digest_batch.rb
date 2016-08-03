class WebPushDigestBatch < ActiveRecord::Base

  include Redis::Objects
  value :current_processed_client_id

  belongs_to :shop
  belongs_to :mailing, class_name: 'WebPushDigest', foreign_key: 'web_push_digest_id'
  has_many :web_push_digest_messages

  scope :incomplete, -> { where(completed: false) }

  validates :mailing, presence: true
  validates :shop_id, presence: true
  validates :start_id, presence: true
  validates :end_id, presence: true

  def complete!
    update(completed: true)
  end

end
