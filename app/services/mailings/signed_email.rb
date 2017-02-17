##
# Подписанное DKIM письмо. Это лучше вынести в постфикс.
#
module Mailings
  class SignedEmail < ActionMailer::Base
    # Создать письмо со всеми нужными параметрами и заголовками и подписать его
    def compose(shop, options)
      @shop = shop
      @options = options

      m = mail(to: options.fetch(:to),
           subject: options.fetch(:subject),
           from: options.fetch(:from).gsub('"',"'"),
           return_path: generate_return_path) do |format|
        format.text { render text: ActionView::Base.full_sanitizer.sanitize(options.fetch(:body)) }
        format.html { render text: options.fetch(:body).html_safe }
      end
      m.transport_encoding = 'base64'

      type = @options.fetch(:type)
      code = @options[:code] || 'test'
      unsubscribe_email = "unsubscribe+#{type}=#{code}@rees46.com"
      unsubscribe_url = Routes.unsubscribe_subscriptions_url(type: type, code: code, host: Rees46::HOST, shop_id: shop.uniqid)
      m.header['List-Unsubscribe'] = "<#{unsubscribe_url}>,<mailto:#{unsubscribe_email}>"

      m.header['List-Id'] = @options.fetch(:list_id)
      m.header['Feedback-ID'] = @options.fetch(:feedback_id)

      # Bounced ID for Get-N-Post API
      m.header['X-R46-ID'] = "shard#{SHARD_ID}+#{type}=#{code}"

      if @options.fetch(:type) == 'digest'
        m.header['Precedence'] = 'bulk'
      end

      sign(m)
    end

    private

    # Это нужно для отслеживания bounce
    def generate_return_path
      type = @options.fetch(:type)
      code = @options[:code] || 'test'
      "bounce+shard#{SHARD_ID}+#{type}=#{code}@bounce.rees46.com"
    end

    def sign(m)
      private_key = OpenSSL::PKey::RSA.new(Rails.application.secrets.dkim_key)
      signed_mail = Dkim::SignedMail.new(m,
        domain: 'rees46.com',
        selector: 'default',
        private_key: private_key)
      m.header['DKIM-Signature'] = signed_mail.dkim_header.value
      m
    end
  end
end
