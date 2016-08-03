class WebPushDigest < ActiveRecord::Base

  class DisabledError < StandardError; end

  include Redis::Objects
  counter :sent_messages_count
  belongs_to :shop
  has_many :web_push_digest_batches
  has_many :web_push_digest_messages

  has_attached_file :picture, styles: { original: '500x500>', main: '192>x', medium: '130>x', small: '100>x' }
  validates_attachment_content_type :picture, content_type: /\Aimage/
  validates_attachment_file_name :picture, matches: [/png\Z/i, /jpe?g\Z/i]

  validates :subject, :message, :url, presence: true

  def fail!
    update(state: 'failed')
  end

  def failed?
    self.state == 'failed'
  end

  def started?
    self.state == 'started'
  end

  def finish!
    update(state: 'finished', finished_at: Time.current)
  end

  # Возобновить сломавшуюся рассылку
  def resume!
    update(state: 'started')
    raise NotImpementedError.new 'Not implemented'
  end

  # Запустить рассылку
  def start!
    update(state: 'started')
    raise NotImpementedError.new 'Not implemented'
  end


  # Возвращает полный URL к картинке дайджеста
  def fetch_picture_url
    self.picture.present? ? URI.join("#{Rees46.site_url}", self.picture.url).to_s : ''
  end


end
