class TestMailer < ActionMailer::Base
  default from: 'REES46 <desk@rees46.com>'
  def mailerq
    # mail(to: 'kechinoff@gmail.com', subject: 'check smtp', from: 'support@rees46.com', body: 'smtp works', transport_encoding: 'base64', delivery_method_options: {address: '94.130.66.43'}).deliver_now
    mail(to: 'kechinoff@gmail.com', subject: 'check smtp', from: 'support@rees46.com', body: 'smtp works', transport_encoding: 'base64').deliver_now
  end
end
