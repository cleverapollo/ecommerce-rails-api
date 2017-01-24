class ErrorsMailer < ActionMailer::Base
  default from: 'REES46 <reports@rees46.com>',
          bcc: ['mk@rees46.com', 'av@rees46.com', 'dz@rees46.com']

  def yml_import_error(shop, reason)
    @shop = shop
    @reason = reason
    I18n.locale = @shop.customer.language || 'en'
    @manager = @shop.manager || Customer.default_manager(I18n.locale.to_s)

    m = mail(from: @manager.email, to: @shop.customer.email, bcc: @manager.email, subject: I18n.t('errors_mailer.subject.yml_import_error'))
    m.header['List-Id'] = "<notification errors_mailer:yml_import_error>"
    m.header['Feedback-ID'] = "#{@shop.customer.email}:yml_import_error:errors_mailer:rees46mailer"
    m
  end

  def yml_url_not_respond(shop)
    @shop = shop
    I18n.locale = @shop.customer.language || 'en'
    @manager = @shop.manager || Customer.default_manager(I18n.locale.to_s)

    m = mail(from: @manager.email, to: @shop.customer.email, bcc: @manager.email, subject: I18n.t('errors_mailer.subject.yml_url_not_respond'))
    m.header['List-Id'] = "<notification errors_mailer:yml_url_not_respond>"
    m.header['Feedback-ID'] = "#{@shop.customer.email}:yml_url_not_respond:errors_mailer:rees46mailer"
    m
  end

  def yml_syntax_error(shop, message)
    @shop = shop
    @message = message
    I18n.locale = @shop.customer.language || 'en'
    @manager = shop.manager || Customer.default_manager(I18n.locale.to_s)

    m = mail(from: @manager.email, to: @shop.customer.email, bcc: @manager.email, subject: I18n.t('errors_mailer.subject.yml_syntax_error'))
    m.header['List-Id'] = "<notification errors_mailer:yml_syntax_error>"
    m.header['Feedback-ID'] = "#{@shop.customer.email}:yml_syntax_error:errors_mailer:rees46mailer"
    m
  end

  def yml_off(shop)
    @shop = shop
    I18n.locale = @shop.customer.language || 'en'
    @manager = shop.manager || Customer.default_manager(I18n.locale.to_s)

    m = mail(from: @manager.email, to: @shop.customer.email, bcc: @manager.email, subject: I18n.t('errors_mailer.subject.yml_off'))
    m.header['List-Id'] = "<notification errors_mailer:yml_off>"
    m.header['Feedback-ID'] = "#{@shop.customer.email}:yml_off:errors_mailer:rees46mailer"
    m
  end


  ## Orders Import Errors

  def orders_import_error(email, message, params)
    mail(to: email, bcc: [], subject: "Ошибка при импорте заказов") do |format|
      format.text { render text: "#{message}\n\n\n#{params.inspect}" }
      format.html { render text: "#{message}<hr/>#{params.inspect}" }
    end
  end

  # Сообщаем о полной или частичной обработке импорта заказов
  def orders_import_processed(shop, errors)
    manager =  shop.manager.present? ? shop.manager : Customer.default_manager
    if errors.map {|x| x[1] }.flatten.any?
      mail(from: manager.email, to: shop.customer.email, bcc: manager.email, subject: 'Не все заказы импортированы в REES46') do |format|
        message = "Добрый день!\n\nК сожалению, не все ваши заказы были импортированы в REES46 по следующим причинам:\n\n"
        if errors[:order_without_id].any?
          message += "** Заказы без ID [#{errors[:order_without_id].count}]:\n\n"
          errors[:order_without_id].each do |row|
            message += "- #{row.inspect}\n"
          end
          message += "\n"
        end
        if errors[:order_without_user_id].any?
          message += "** Заказы без идентификатора покупателя [#{errors[:order_without_user_id].count}]:\n\n"
          errors[:order_without_user_id].each do |row|
            message += "- #{row.inspect}\n"
          end
          message += "\n"
        end
        if errors[:order_without_items].any?
          message += "** Заказы без товаров [#{errors[:order_without_items].count}]:\n\n"
          errors[:order_without_items].each do |row|
            message += "- #{row.inspect}\n"
          end
          message += "\n"
        end
        if errors[:order_item_without_id].any?
          message += "** Заказы с товарами без ID [#{errors[:order_item_without_id].count}]:\n\n"
          errors[:order_item_without_id].each do |row|
            message += "- #{row.inspect}\n"
          end
          message += "\n"
        end
        format.text { render text: message }
      end
    else
      mail(from: manager.email, to: shop.customer.email, bcc: manager.email, subject: 'Заказы импортированы в REES46') do |format|
        format.text {
          "Добрый день!\n\nВаши заказы полностью импортированы в REES46\n\nУдачной работы,\nКоманда REES46"
        }
      end
    end
  end

end
