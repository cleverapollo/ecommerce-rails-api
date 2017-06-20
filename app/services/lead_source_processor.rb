class LeadSourceProcessor

  attr_accessor :channel, :id

  def initialize(channel, id)
    @channel = channel
    @id = id
  end

  # @return [TriggerMail|DigestMail|RtbImpression|WebPushTriggerMessage|WebPushDigestMessage|nil]
  def process
    if @channel && @id && @id != 'test'
      case @channel
        when 'trigger_mail'
          TriggerMail.find_by(code: @id).try(:mark_as_clicked!)
        when 'digest_mail'
          DigestMail.find_by(code: @id).try(:mark_as_clicked!)
        when 'r46_returner'
          RtbImpression.find_by(code: @id).try(:mark_as_clicked!)
        when 'web_push_trigger'
          WebPushTriggerMessage.find_by(code: @id).try(:mark_as_clicked!)
        when 'web_push_digest'
          WebPushDigestMessage.find_by(code: @id).try(:mark_as_clicked!)
        else
          nil
      end
    end
  end

end
