##
# Содержит общие методы для рассылок.
#
module Mailings
  class Composer
    class << self
      def footer(options = {})
        email = options.fetch(:email)
        tracking_url = options.fetch(:tracking_url)
        unsubscribe_url = options.fetch(:unsubscribe_url)

        <<-HTML
          This letter was sent to <a href="mailto:#{email}">#{email}</a>.<br>
          If you does not want to receive similar letters, you can <a href="#{unsubscribe_url}">unsubscribe</a> from these offers.
          <img src="#{tracking_url}" alt=""></img>
        HTML
      end

      def utm_params(mail, options = {})
        result = nil
        if mail.class.name == 'TriggerMail'
          result = {
            rees46_source: 'trigger_mail',
            rees46_campaign: mail.mailing.trigger_type,
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
