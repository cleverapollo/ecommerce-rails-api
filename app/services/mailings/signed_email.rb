module Mailings
  class SignedEmail < ActionMailer::Base
    DKIM_KEY = "-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgQDbAeDhlZvNa/EgOJlOnDzkxuuIJLLgtE2gFW7YxqyKh1P4mMtW
esecRVDhgf2orVkYPZ/7Ncz6WrBXEeAUy5LAPLssVbNpHnBheBgwEI1jZRvLRom5
i723iEEpiNqyK/83Tewk6DUWJZ4VKXqccxTQopg4OwozjI4u3sg0SI/NRQIDAQAB
AoGAacGDdYuIO+829gc+yL4bjaIdFJYcJvQKVBZle5qcsRxeSTqHXlBV2bmDMBJU
ikKDNnhzq5w0SmTGqJUCLyiKyRL22bBkHKssQe8URUWWqqGS5gkYIJMIjXFcJ8qM
8NnsjUzLE6Uw5M5Z2eAywcrF+y6LiL6CqsGYKcN3qQ/UxLUCQQD1Xk38rA8YdGNb
Plc+kp1TJLWNa95DktdenF9XorRe3L8FByzVHEibWQRdmKyWkOWPcyYYAlieOWXZ
qdJajA2rAkEA5H8rcb4xL8YgJDG/9H8xVNveJFzE7AWhAr7u2NJc9MCg9nQ3vifT
GoDskop7/KXHuHd/cC62tp8MspCKp7JAzwJAd5BHkktJY9I7JBghrUUGUqB9s3cP
rH/eYKT0NKD9IYiRsGKJryMEImbjILSnzQq4QgmLU4G5KwivH7yH20WJ1wJABx97
wDj4mY+okthGLp4EcKvF+gY2UVE/mrFPCs1L/ok+u1AWKMRfDVV1in/sq4yTdEmt
XFbodTryD2L4H5Ar+wJATpy5hb9HVJutZOP5/ACFHNBH0gmqFtAP7ly16/BsqDuW
ZuwC9tVPGOkmzt/1UD7ucBg1wyQ7csCe2+hNL6lgUQ==
-----END RSA PRIVATE KEY-----"

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

      type = @options.fetch(:type)
      code = @options[:code] || 'test'
      unsubscribe_email = "unsubscribe+#{type}=#{code}@rees46.com"
      unsubscribe_url = Rails.application.routes.url_helpers.unsubscribe_subscriptions_url(type: type, code: code, host: Rees46.host)
      mail.header['List-Unsubscribe'] = "<mailto:#{unsubscribe_email}>, <#{unsubscribe_url}>"

      if @options.fetch(:type) == 'digest'
        mail.header['Precedence'] = 'bulk'
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
      private_key = OpenSSL::PKey::RSA.new(DKIM_KEY)
      signed_mail = Dkim::SignedMail.new(mail,
        domain: 'rees46.com',
        selector: 'default',
        private_key: private_key)
      mail.header['DKIM-Signature'] = signed_mail.dkim_header.value
      mail
    end
  end
end
