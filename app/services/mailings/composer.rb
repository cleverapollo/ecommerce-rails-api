module Mailings
  class Composer
    class << self
      def footer(options = {})
        email = options.fetch(:email)
        tracking_url = options.fetch(:tracking_url)
        unsubscribe_url = options.fetch(:unsubscribe_url)

        <<-HTML
          <div style="max-width:600px; font-family:sans-serif; color:#666; font-size:9px; text-align:left;">
            Письмо было отправлено на <a href="mailto:#{email}">#{email}</a>.
            <br />
            Если вы не хотите получать подобные письма, вы можете <a href="#{unsubscribe_url}">отписаться</a> от рассылок.
            <br />
            <img src="#{tracking_url}"></img>
          </div>
        HTML
      end

      def utm_params(mail, options = {})
        result = nil
        if mail.class == TriggerMail
          result = {
            utm_source: 'rees46',
            utm_meta: 'trigger_mail',
            utm_campaign: mail.mailing.trigger_type,
            recommended_by: 'trigger_mail',
            rees46_trigger_mail_code: mail.code
          }

          if options[:as] == :string
            result = result.map{|k,v| "#{k}=#{v}" }.join('&')
          end
        end

        result
      end
    end
  end
end
