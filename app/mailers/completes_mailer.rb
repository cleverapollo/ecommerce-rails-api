class CompletesMailer < ActionMailer::Base
  default from: 'REES46 <reports@rees46.com>',
          bcc: ['mk@rees46.com', 'av@rees46.com', 'dz@rees46.com']

  def orders_import_completed(email, orders_count)
    mail(to: email, bcc: [], subject: I18n.t('complete_mailers.orders_import.subject')) do |format|
      format.html {
                    "<p>#{I18n.t('complete_mailers.orders_import.body_text')}
                    <br/>
                    #{I18n.t('complete_mailers.orders_import.body_count', orders_count: orders_count)}</p>
                    <br/>
                    <p>#{I18n.t('complete_mailers.orders_import.tail')}</p>
                    <p>#{I18n.t('complete_mailers.orders_import.team')}</p>"
                  }
    end
  end
end
