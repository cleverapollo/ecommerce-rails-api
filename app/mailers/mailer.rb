class Mailer < ActionMailer::Base
  def digest(params)
    mail(to: params[:email], subject: params[:subject], from: params[:send_from]) do |format|
      format.text { render text: params[:body].html_safe }
      format.html { render text: params[:body].html_safe }
    end
  end

  def recommendations(params)
    attachments['recommendations.csv'] = params[:recommendations]
    mail(to: params[:email], subject: 'Расчет рекомендаций завершен', from: 'REES46 <noreply@rees46.com>') do |format|
      format.text { render text: 'Рекомендации во вложении.' }
      format.html { render text: 'Рекомендации во вложении.' }
    end
  end
end
