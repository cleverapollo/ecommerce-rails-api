class TestMailer < ActionMailer::Base
  default from: 'REES46 <desk@rees46.com>'
  def mailerq
    mail(to: 'd.jeshkov@gmail.com', subject: 'check smtp', from: 'support@rees46.com', body: 'smtp works', transport_encoding: 'base64', delivery_method_options: {address: '94.130.66.43'}, delivery_method: :smtp)
    # mail(to: 'kechinoff@gmail.com', subject: 'check smtp', from: 'support@rees46.com', body: 'smtp works')
  end
end
