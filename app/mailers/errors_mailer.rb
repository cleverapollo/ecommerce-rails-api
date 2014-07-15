class ErrorsMailer < ActionMailer::Base
  default from: 'REES46 <mk@rees46.com>'

  def orders_import_error(customer, message)
    mail(to: customer.email, subject: "Ошибка при импорте заказов") do |format|
      format.text { render text: message }
      format.html { render text: message }
    end.deliver
  end
end
