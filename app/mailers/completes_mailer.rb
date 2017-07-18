class CompletesMailer < ActionMailer::Base
  default from: 'REES46 <desk@rees46.com>',
          bcc: ['notify@rees46.com']

  def orders_import_completed(shop, orders_count)
    manager =  shop.manager.present? ? shop.manager : Customer.default_manager
    mail(from: manager.email, to: shop.customer.email, bcc: manager.email, subject: I18n.t('complete_mailers.orders_import.subject')) do |format|
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

  def audiance_import_completed(shop, audiance_count)
    manager =  shop.manager.present? ? shop.manager : Customer.default_manager
    mail(from: manager.email, to: shop.customer.email, bcc: manager.email, subject: I18n.t('complete_mailers.orders_import.subject')) do |format|
      format.html {
                    "<p>#{I18n.t('complete_mailers.audiance_import.body_text')}
                    <br/>
                    #{I18n.t('complete_mailers.audiance_import.body_count', audiance_count: audiance_count)}</p>
                    <br/>
                    <p>#{I18n.t('complete_mailers.audiance_import.tail')}</p>
                    <p>#{I18n.t('complete_mailers.audiance_import.team')}</p>"
                  }
    end
  end
end
