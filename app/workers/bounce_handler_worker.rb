##
# Обработчик отклоненных писем
#
class BounceHandlerWorker
  class << self
    def perform
      require 'gmail'
      require 'bounce_email'

      Gmail.connect!('bounced@rees46.com', Rails.application.secrets.gmail_bounced_password) do |gmail|
        gmail.inbox.emails.each do |email|
          # Достаем "само" письмо
          message = email.message
          bounced_message = BounceEmail::Mail.new(email.message)

          if bounced_message.is_bounce? && bounced_message.type == 'Permanent Failure'
            # Адрес получателя
            to = message.to.first

            # Работаем только с письмами текущего шарда
            if shard = to.match(/shard(\d{2})/)
              if shard[1] == SHARD_ID

                type = to.split('bounced+', 2).last.split('@', 2).first.split('=', 2).first
                code = to.split('bounced+', 2).last.split('@', 2).first.split('=', 2).last

                if code != 'test'
                  entity = if type == 'digest'
                             DigestMail.find_by(code: code)
                           elsif type == 'trigger'
                             TriggerMail.find_by(code: code)
                           end

                  entity.mark_as_bounced! if entity.present?
                end

                # Архивируем письмо
                email.delete!

              end
            end

          end
        end
      end
    end

    # Чистит письма, не относящиеся к боунсам (спам, ответы и прочий мусор), чтобы ящик не засорялся
    # В будущем имеет смысл вынести как отдельную службу, чтобы не запускать одинаковые задачи на нескольких шардах.
    def cleanup
      require 'gmail'
      Gmail.connect!('bounced@rees46.com', Rails.application.secrets.gmail_bounced_password) do |gmail|
        gmail.inbox.emails.each do |email|
          message = email.message
          unless message.to.first.match(/shard(\d{2})/)
            email.delete!
          end
        end
      end
    end

  end
end
