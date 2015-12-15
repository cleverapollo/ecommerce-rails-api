class YMLMailer < ActionMailer::Base
  default from: 'REES46 <mk@rees46.com>',
          bcc: ['mk@rees46.com', 'av@rees46.com', 'dz@rees46.com']

  add_template_helper(ApplicationHelper)

  def report(report_dump)
    @report = YAML.load(report_dump)

    mail to: 'andrey.zinenko@mkechinov.ru', subject: "Ошибки при импорте заказов [#{ @report.shop_id }]"
  end
end