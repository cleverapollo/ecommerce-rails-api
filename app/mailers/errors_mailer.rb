class ErrorsMailer < ActionMailer::Base
  default from: 'REES46 <mk@rees46.com>'

  def orders_import_error(email, message, params)
    mail(to: email, subject: "Ошибка при импорте заказов") do |format|
      format.text { render text: "#{message}\n\n\n#{params.inspect}" }
      format.html { render text: "#{message}<hr/>#{params.inspect}" }
    end.deliver
  end

  def yml_import_error(email, exception, shop_id)
    mail(to: email, subject: "Ошибка при импорте YML") do |format|
      format.text { render text: "Shop #{shop_id}\n\n\n#{exception.class}: #{exception.message} #{exception.backtrace}" }
      format.html { render text: "Shop #{shop_id}<hr/>#{exception.class}: #{exception.message} #{exception.backtrace}" }
    end.deliver
  end
end
