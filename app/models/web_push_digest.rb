class WebPushDigest < ActiveRecord::Base

  class DisabledError < StandardError; end

  include Redis::Objects
  counter :sent_messages_count
  belongs_to :shop


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


end
