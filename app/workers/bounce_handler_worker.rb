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
      imap.examine('INBOX')

      imap.search('RECENT').map do |m|

        raw_message = imap.fetch(m, '(ENVELOPE BODY)').first
        envelope = raw_message.attr['ENVELOPE']
        to = envelope.to.first.mailbox

        # Если получателя нет (бывает, что в групповых письмах Gmail его нет), то удаляем письмо
        unless to.present?
          imap.store(m, "+FLAGS", [:Deleted])
          next
        end

        # Если получатель не bounce, то удаляем письмо
        unless to.scan(/bounced\+shard\d+.+rees46\.com/).any?
          imap.store(m, "+FLAGS", [:Deleted])
          next
        end

        # Если письмо не из этого шарда, пропускаем его
        if to.match(/shard(\d{2})/)[1] != SHARD_ID
          next
        end

        message = Mail.new raw_message
        bounced_message = BounceEmail::Mail.new(email.message)
        bounced_message.charset = 'UTF-8'


        # Если письмо bounced?
        # @mk: добавил условие на тип, потому что mail.ru почему-то возвращал боунсы без кода боунса, в итоге тип был
        # "permanent failure", а is_bounce? был false и письма не обрабатывались.
        if bounced_message.is_bounce? || bounced_message.type == 'Permanent Failure'

          # Если Permanent Failure
          if bounced_message.type == 'Permanent Failure'

            type = to.split("bounced+shard#{SHARD_ID}+", 2).last.split('@', 2).first.split('=', 2).first
            code = to.split("bounced+shard#{SHARD_ID}+", 2).last.split('@', 2).first.split('=', 2).last

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

        # Remove all emails marked as deleted
        imap.expunge

        imap.disconnect

      end



      # Gmail.connect!('bounced@rees46.com', Rails.application.secrets.gmail_bounced_password) do |gmail|
      #   gmail.inbox.emails.each do |email|
      #     # Достаем "само" письмо
      #     message = email.message
      #     bounced_message = BounceEmail::Mail.new(email.message)
      #     bounced_message.charset = 'UTF-8'
      #
      #     # Если получателя нет (бывает, что в групповых письмах Gmail его нет), то удаляем письмо
      #     unless message.to.present?
      #       email.delete!
      #       next
      #     end
      #
      #     # Получатель
      #     to = message.to.first
      #
      #     # Если получатель не bounce, то удаляем письмо
      #     unless to.scan(/bounced\+shard\d+.+rees46\.com/).any?
      #       email.delete!
      #       next
      #     end
      #
      #     # Если письмо не из этого шарда, пропускаем его
      #     if to.match(/shard(\d{2})/)[1] != SHARD_ID
      #       next
      #     end
      #
      #     # Если письмо bounced?
      #     # @mk: добавил условие на тип, потому что mail.ru почему-то возвращал боунсы без кода боунса, в итоге тип был
      #     # "permanent failure", а is_bounce? был false и письма не обрабатывались.
      #     if bounced_message.is_bounce? || bounced_message.type == 'Permanent Failure'
      #
      #       # Если Permanent Failure
      #       if bounced_message.type == 'Permanent Failure'
      #
      #         type = to.split("bounced+shard#{SHARD_ID}+", 2).last.split('@', 2).first.split('=', 2).first
      #         code = to.split("bounced+shard#{SHARD_ID}+", 2).last.split('@', 2).first.split('=', 2).last
      #
      #         if code != 'test'
      #           entity = if type == 'digest'
      #                      DigestMail.find_by(code: code)
      #                    elsif type == 'trigger'
      #                      TriggerMail.find_by(code: code)
      #                    end
      #
      #           entity.mark_as_bounced! if entity.present?
      #         end
      #
      #       end
      #
      #       # Если Persistent Transient Failure, то в следующий раз повезет, просто удаляем
      #       # nope
      #
      #       email.delete!
      #
      #     end
      #
      #   end
      # end
    end


    # Обрабатывает письма FBL
    def perform_feedback_loop
      require 'gmail'

      # http://y.mkechinov.ru/issue/REES-2541
      begin
        OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ssl_version] = 'TLSv1'
      rescue => e
        Rollar.error e
      end

      Gmail.connect!('fbl@rees46.com', Rails.application.secrets.mailru_fbl_password) do |gmail|
        gmail.inbox.emails.each do |email|

          # Достаем "само" письмо
          message = email.message

          # Ищем в теле наши адреса для боунсов
          if bounced_address = message.body.match(/bounced\+shard.+@rees46.com/)
            bounced_address = bounced_address[0]

            # Не текущий шард, поэтому пропускаем
            if bounced_address.match(/shard(\d{2})/)[1] != SHARD_ID
              next
            end

            type = bounced_address.split("bounced+shard#{SHARD_ID}+", 2).last.split('@', 2).first.split('=', 2).first
            code = bounced_address.split("bounced+shard#{SHARD_ID}+", 2).last.split('@', 2).first.split('=', 2).last

            if code != 'test'
              entity = if type == 'digest'
                         DigestMail.find_by(code: code)
                       elsif type == 'trigger'
                         TriggerMail.find_by(code: code)
                       end

              entity.mark_as_bounced! if entity.present?
            end

            # Удаляем письмо
            email.delete!

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
