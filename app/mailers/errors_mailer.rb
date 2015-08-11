class ErrorsMailer < ActionMailer::Base
  default from: 'REES46 <mk@rees46.com>'

  def orders_import_error(email, message, params)
    mail(to: email, subject: "Ошибка при импорте заказов") do |format|
      format.text { render text: "#{message}\n\n\n#{params.inspect}" }
      format.html { render text: "#{message}<hr/>#{params.inspect}" }
    end
  end

  def yml_import_error(shop, reason)
    manager =  shop.manager.present? ? shop.manager : Customer.default_manager
    mail(from: manager.email, to: shop.customer.email, bcc: manager.email, subject: 'Не правильно указан yml файл') do |foramt|
      foramt.html { "<p>Здравствуйте!</p><p>К сожалению мы не смогли обработать YML-файл вашего интернет-магазина  <a href='#{shop.url}'>#{shop.name}</a>. <br />В процессе обработки возникли следующая ошибка: #{reason}</p><p>Пожалуйста, проверьте корректность YML-файла и при необходимости измените ссылку на YML-файл в настройках магазина в <a href='#{Rees46.site_url}/shops/#{shop.id}'>личном кабинете</a>.</p><p>На все ваши вопросы ответит ваш менеджер #{manager.name}. <br /><a href='http://rees46.com' target='_blank'>rees46.com</a> | <a href='mailto:#{manager.email}' target='_blank'>#{manager.email}</a> | +7 (812) 426-13-45 </p>" }
    end
  end

  def yml_url_not_respond(shop)
    manager =  shop.manager.present? ? shop.manager : Customer.default_manager
    mail(from: manager.email, to: shop.customer.email, bcc: manager.email, subject: 'Не удалось загрузить YML-файл') do |foramt|
      foramt.html { "<p>Здравствуйте!</p><p>К сожалению мы не смогли загрузить YML-файл вашего интернет-магазина <a href='#{shop.url}'>#{shop.name}</a>. <br />Пожалуйста, проверьте правильность ссылки, указанной в <a href='#{Rees46.site_url}/shops/#{shop.id}'>личном кабинете</a>.</p><p>На все ваши вопросы ответит ваш менеджер #{manager.name}. <br /><a href='http://rees46.com' target='_blank'>rees46.com</a> | <a href='mailto:#{manager.email}' target='_blank'>#{manager.email}</a> | +7 (812) 426-13-45 </p>" }
    end
  end

  def yml_off(shop)
        manager =  shop.manager.present? ? shop.manager : Customer.default_manager
    mail(from: manager.email, to: shop.customer.email, bcc: manager.email, subject: 'Обработка YML-файла отключена') do |foramt|
      foramt.html { "<p>Здравствуйте!</p><p>К сожалению мы не смогли загрузить YML-файл вашего интернет-магазина <a href='#{shop.url}'>#{shop.name}</a> в течение 5-ти дней. </br />Пожалуйста, проверьте правильность ссылки, указанной в <a href='#{Rees46.site_url}/shops/#{shop.id}'>личном кабинете</a>.</p><p>На все ваши вопросы ответит ваш менеджер #{manager.name}. <br /><a href='http://rees46.com' target='_blank'>rees46.com</a> | <a href='mailto:#{manager.email}' target='_blank'>#{manager.email}</a> | +7 (812) 426-13-45 </p>" }
    end
  end
end
