##
# Подписанное DKIM письмо. Это лучше вынести в постфикс.
#
module Mailings

  class DefaultMail
    class << self
      # Создает обычное письмо через гем Mail
      def compose(shop, options)
        @shop = shop
        @options = options

        m = Mail.new do
          to          options.fetch(:to)
          from        options.fetch(:from).gsub('"',"'")
          subject     options.fetch(:subject)

          text_part do
            content_type 'text/plain; charset=utf-8'
            body HtmlToPlainText.convert_to_text(options.fetch(:body))
          end

          html_part do
            content_type 'text/html; charset=UTF-8'
            body options.fetch(:body).html_safe
          end
        end
        m.charset = 'UTF-8'
        m.return_path = generate_return_path
        m.delivery_method Rails.application.config.action_mailer.delivery_method
        m.transport_encoding = 'base64'

        type = @options.fetch(:type)
        code = @options[:code] || 'test'
        unsubscribe_email = "unsubscribe+#{type}=#{code}@rees46.com"
        m.header['List-Unsubscribe'] = "<#{options.fetch(:unsubscribe_url)}>,<mailto:#{unsubscribe_email}>"

        m.header['List-Id'] = @options.fetch(:list_id)
        m.header['Feedback-ID'] = @options.fetch(:feedback_id)

        # Bounced ID for Get-N-Post API
        m.header['X-R46-ID'] = "shard#{SHARD_ID}+#{type}=#{code}"

        if @options.fetch(:type) == 'digest'
          m.header['Precedence'] = 'bulk'
        end

        m
      end

      private

      # Это нужно для отслеживания bounce
      def generate_return_path
        type = @options.fetch(:type)
        code = @options[:code] || 'test'
        "bounce+shard#{SHARD_ID}+#{type}=#{code}@bounce.rees46.com"
      end

    end
  end
end
