##
# Обработчик отклоненных писем
#
class BounceHandlerWorker
  class << self
    def perform
      require 'net/imap'
      require 'bounce_email'

      # http://y.mkechinov.ru/issue/REES-2541
      begin
        OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ssl_version] = 'TLSv1'
      rescue => e
        Rollar.error e
      end

      imap = Net::IMAP.new Rails.application.secrets.bounced_email_host
      imap.login Rails.application.secrets.bounced_email_user, Rails.application.secrets.bounced_email_pass
      imap.select('INBOX')

      imap.search('ALL').map do |m|

        raw_message = imap.fetch(m, '(ENVELOPE BODY)').first
        envelope = raw_message.attr['ENVELOPE']

        if envelope.to.nil?
          imap.store(m, "+FLAGS", [:Deleted])
          next
        end

        to = envelope.to.first.mailbox

        # Если получателя нет (бывает, что в групповых письмах Gmail его нет), то удаляем письмо
        unless to.present?
          imap.store(m, "+FLAGS", [:Deleted])
          next
        end

        # Если получатель не bounce, то удаляем письмо
        unless to.scan(/bounce\+shard\d+.+/).any?
          imap.store(m, "+FLAGS", [:Deleted])
          next
        end

        # Если письмо не из этого шарда, пропускаем его
        if to.match(/shard(\d{2})/)[1] != SHARD_ID
          next
        end

        bounced_message = BounceEmail::Mail.new Mail.new(raw_message)
        bounced_message.charset = 'UTF-8'


        # Если письмо bounced?
        # @mk: добавил условие на тип, потому что mail.ru почему-то возвращал боунсы без кода боунса, в итоге тип был
        # "permanent failure", а is_bounce? был false и письма не обрабатывались.
        if bounced_message.is_bounce? || bounced_message.type == 'Permanent Failure'

          # Если Permanent Failure
          if bounced_message.type == 'Permanent Failure'

            type = to.split("bounce+shard#{SHARD_ID}+", 2).last.split('@', 2).first.split('=', 2).first
            code = to.split("bounce+shard#{SHARD_ID}+", 2).last.split('@', 2).first.split('=', 2).last

            if code != 'test'
              entity = if type == 'digest'
                         DigestMail.find_by(code: code)
                       elsif type == 'trigger'
                         TriggerMail.find_by(code: code)
                       end

              entity.mark_as_bounced! if entity.present?
            end

          end

          # Если Persistent Transient Failure, то в следующий раз повезет, просто удаляем
          # nope

          # Отмечаем для удаления
          imap.store(m, "+FLAGS", [:Deleted])

        end

      end

      # Remove all emails marked as deleted
      imap.expunge

      imap.disconnect

    end


    # Обрабатывает письма FBL
    def perform_feedback_loop

      require 'net/imap'

      # http://y.mkechinov.ru/issue/REES-2541
      begin
        OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ssl_version] = 'TLSv1'
      rescue => e
        Rollar.error e
      end

      imap = Net::IMAP.new Rails.application.secrets.fbl_email_host
      imap.login Rails.application.secrets.fbl_email_user, Rails.application.secrets.fbl_email_pass
      imap.select('INBOX')

      imap.search('ALL').map do |m|

        raw_message = imap.fetch(m, 'RFC822').first.attr['RFC822']
        mail = Mail.read_from_string raw_message
        body = ""
        if mail.text_part
          body = "#{body} #{mail.text_part.body.to_s}"
        end
        if mail.html_part
          body = "#{body} #{mail.html_part.body.to_s}"
        end

        # Ищем в теле наши адреса для боунсов
        if bounced_address = body.match(/bounce\+shard.+@bounce.rees46.com/)
          bounced_address = bounced_address[0]

          # Не текущий шард, поэтому пропускаем
          if bounced_address.match(/shard(\d{2})/)[1] != SHARD_ID
            next
          end

          type = bounced_address.split("bounce+shard#{SHARD_ID}+", 2).last.split('@', 2).first.split('=', 2).first
          code = bounced_address.split("bounce+shard#{SHARD_ID}+", 2).last.split('@', 2).first.split('=', 2).last

          if code != 'test'
            entity = if type == 'digest'
                       DigestMail.find_by(code: code)
                     elsif type == 'trigger'
                       TriggerMail.find_by(code: code)
                     end

            entity.mark_as_bounced! if entity.present?
          end

        end

        # Удаляем письмо
        imap.store(m, "+FLAGS", [:Deleted])

      end

      # Remove all emails marked as deleted
      imap.expunge

      imap.disconnect

    end



    # Чистит письма, не относящиеся к боунсам (спам, ответы и прочий мусор), чтобы ящик не засорялся
    # В будущем имеет смысл вынести как отдельную службу, чтобы не запускать одинаковые задачи на нескольких шардах.
    def cleanup
      require 'net/imap'
      imap = Net::IMAP.new Rails.application.secrets.bounced_email_host
      imap.login Rails.application.secrets.bounced_email_user, Rails.application.secrets.bounced_email_pass
      imap.select('INBOX')

      imap.search('ALL').map do |m|

        raw_message = imap.fetch(m, '(ENVELOPE BODY)').first
        envelope = raw_message.attr['ENVELOPE']
        to = envelope.to.first.mailbox

        # Если получателя нет (бывает, что в групповых письмах Gmail его нет), то удаляем письмо
        unless to.match(/shard(\d{2})/)
          imap.store(m, "+FLAGS", [:Deleted])
          next
        end

      end

      # Remove all emails marked as deleted
      imap.expunge

      imap.disconnect

    end

  end
end
