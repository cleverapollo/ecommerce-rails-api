class ErrorsMailer < ActionMailer::Base
  default from: 'REES46 <reports@rees46.com>',
          bcc: ['mk@rees46.com', 'av@rees46.com', 'dz@rees46.com']

  def orders_import_error(email, message, params)
    mail(to: email, bcc: [], subject: "Ошибка при импорте заказов") do |format|
      format.text { render text: "#{message}\n\n\n#{params.inspect}" }
      format.html { render text: "#{message}<hr/>#{params.inspect}" }
    end
  end

  def yml_import_error(shop, reason)
    manager =  shop.manager.present? ? shop.manager : Customer.default_manager
    mail(from: manager.email, to: shop.customer.email, bcc: manager.email, subject: 'Неправильно указан YML файл') do |format|
      format.html { "<p>Здравствуйте!</p><p>К сожалению мы не смогли обработать YML-файл вашего интернет-магазина  <a href='#{shop.url}'>#{shop.name}</a>. <br />В процессе обработки возникла следующая ошибка: #{reason}</p><p>URL файла: <a href='#{shop.yml_file_url}' target='_blank'>#{shop.yml_file_url}</a></p><p>Пожалуйста, проверьте корректность YML-файла и при необходимости измените ссылку на YML-файл в настройках магазина в <a href='#{Rees46.site_url}/shops/#{shop.id}/edit'>личном кабинете</a>.</p><p>Если на момент получения данного письма вы уже внесли все необходимые изменения и YML-файл доступен, то просто проигнорируйте это сообщение.</p><p>На все ваши вопросы ответит ваш менеджер #{manager.name}. <br /><a href='http://rees46.com' target='_blank'>rees46.com</a> | <a href='mailto:#{manager.email}' target='_blank'>#{manager.email}</a> | +7 (812) 426-13-45 </p>" }
    end
  end

  def yml_url_not_respond(shop)
    manager =  shop.manager.present? ? shop.manager : Customer.default_manager
    mail(from: manager.email, to: shop.customer.email, bcc: manager.email, subject: 'Не удалось загрузить YML-файл') do |format|
      format.html { "<p>Здравствуйте!</p><p>К сожалению мы не смогли загрузить YML-файл вашего интернет-магазина <a href='#{shop.url}'>#{shop.name}</a>. <br />Пожалуйста, проверьте правильность ссылки, указанной в <a href='#{Rees46.site_url}/shops/#{shop.id}/edit'>личном кабинете</a>.</p><p>Если на момент получения данного письма вы уже внесли все необходимые изменения и YML-файл доступен, то просто проигнорируйте это сообщение.</p><p>На все ваши вопросы ответит ваш менеджер #{manager.name}. <br /><a href='http://rees46.com' target='_blank'>rees46.com</a> | <a href='mailto:#{manager.email}' target='_blank'>#{manager.email}</a> | +7 (812) 426-13-45 </p>" }
    end
  end

  def yml_syntax_error(shop, message)
    manager =  shop.manager.present? ? shop.manager : Customer.default_manager
    mail(from: manager.email, to: shop.customer.email, bcc: manager.email, subject: 'Ошибка синтаксиса YML-файла') do |format|
      format.html { "<p>Здравствуйте!</p><p>К сожалению мы не смогли обработать YML-файл вашего интернет-магазина <a href='#{shop.url}'>#{shop.name}</a>. <br />Причина: <strong>#{message}</strong></p><p>Пожалуйста, укажите ссылку на корректный YML-файл в <a href='#{Rees46.site_url}/shops/#{shop.id}/edit'>личном кабинете</a>.</p><p>На все ваши вопросы ответит ваш менеджер #{manager.name}. <br /><a href='http://rees46.com' target='_blank'>rees46.com</a> | <a href='mailto:#{manager.email}' target='_blank'>#{manager.email}</a> | +7 (812) 426-13-45 </p>" }
    end
  end

  def yml_off(shop)
        manager =  shop.manager.present? ? shop.manager : Customer.default_manager
    mail(from: manager.email, to: shop.customer.email, bcc: manager.email, subject: 'Обработка YML-файла отключена') do |format|
      format.html { "<p>Здравствуйте!</p><p>К сожалению мы не смогли загрузить YML-файл вашего интернет-магазина <a href='#{shop.url}'>#{shop.name}</a> в течение 5-ти дней. </br />Пожалуйста, проверьте правильность ссылки, указанной в <a href='#{Rees46.site_url}/shops/#{shop.id}/edit'>личном кабинете</a>.</p><p>Если на момент получения данного письма вы уже внесли все необходимые изменения и YML-файл доступен, то просто проигнорируйте это сообщение.</p><p>На все ваши вопросы ответит ваш менеджер #{manager.name}. <br /><a href='http://rees46.com' target='_blank'>rees46.com</a> | <a href='mailto:#{manager.email}' target='_blank'>#{manager.email}</a> | +7 (812) 426-13-45 </p>" }
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
