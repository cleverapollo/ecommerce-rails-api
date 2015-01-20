module Mailings
  class Composer
    class << self
      def footer(mail, shops_user, email = nil)
        email = shops_user.present? ? shops_user.email : email
        tracking_url = mail.present? ? mail.tracking_url : DigestMail.new.tracking_url
        unsubscribe_url = shops_user.present? ? shops_user.digest_unsubscribe_url : ShopsUser.new.digest_unsubscribe_url
        <<-HTML
          Письмо было отправлено на <a href="mailto:#{email}">#{email}</a>. Вы можете <a href="#{unsubscribe_url}">отписаться</a> от рассылок.
          <img src="#{tracking_url}" />
        HTML
      end
    end
  end
end
