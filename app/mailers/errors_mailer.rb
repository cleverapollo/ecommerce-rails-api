class ErrorsMailer < ActionMailer::Base
  default from: 'REES46 <mk@rees46.com>'

  def orders_import_error(email, message, params)
    mail(to: email, subject: "Ошибка при импорте заказов") do |format|
      format.text { render text: "#{message}\n\n\n#{params.inspect}" }
      format.html { render text: "#{message}<hr/>#{params.inspect}" }
    end.deliver
  end

  def yml_import_error(email, shop, exception)
    shop_string = "##{shop.id} #{shop.name} (#{shop.url}) - #{shop.yml_file_url}"
    mail(to: email, subject: "Ошибка при импорте YML") do |format|
      format.text { render text: "#{shop_string}\n\n\n#{exception.message}" }
      format.html { render text: "#{shop_string}<hr />#{exception.message}" }
    end.deliver
  end
end
