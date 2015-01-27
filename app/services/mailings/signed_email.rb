module Mailings
  class SignedEmail < ActionMailer::Base
    def deliver(shop, options)
      @shop = shop
      @options = options

      mail = mail(to: options.fetch(:to),
           subject: options.fetch(:subject),
           from: options.fetch(:from),
           return_path: generate_return_path) do |format|
        format.text { render text: options.fetch(:body).html_safe }
        format.html { render text: options.fetch(:body).html_safe }
      end

      mail = sign(mail)

      mail.deliver
    end

    private

    def generate_return_path
      type = @options.fetch(:type)
      code = @options[:code] || 'test'
      "bounced+#{type}=#{code}@rees46.com"
    end

    def sign(mail)
      private_key = OpenSSL::PKey::RSA.new(@shop.mailings_settings.dkim_private_key)
      signed_mail = Dkim::SignedMail.new(mail,
        domain: @shop.domain,
        selector: 'rees46',
        private_key: private_key)
      mail.header['DKIM-Signature'] = signed_mail.dkim_header.value
      mail
    end
  end
end
