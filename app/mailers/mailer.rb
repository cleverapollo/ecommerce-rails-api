class Mailer < ActionMailer::Base
  def digest(params)
    mail(to: params[:email], subject: params[:subject], from: params[:send_from]) do |format|
      format.text { render text: params[:body].html_safe }
      format.html { render text: params[:body].html_safe }
    end
  end
end
