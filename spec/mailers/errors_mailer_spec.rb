require 'rails_helper'

RSpec.describe ErrorsMailer, type: :mailer do

  describe '#yml_import_error' do
    context 'locale EN' do
      let(:customer) { create(:customer, language: 'en') }
      let(:shop) { create(:shop, customer: customer) }

      let(:mail) { ErrorsMailer.yml_import_error(shop, 'REASON') }
      it 'renders' do
        expect(mail.subject).to eq 'Wrong XML-file URL'
        expect(mail.to).to eq [customer.email]
        expect(mail.from).to eq ['support@rees46.com']
        expect(mail.header['List-Id'].value).to eq '<notification errors_mailer:yml_import_error>'
        expect(mail.header['Feedback-ID'].value).to eq 'yml_import_error:errors_mailer:rees46mailer'
        expect(mail.body.raw_source).to match 'Unfortunately, we could not process your XML Product Feed due to the following reason'
        ActionMailer::Base.deliveries = []
        expect { mail.deliver_now }.to change { ActionMailer::Base.deliveries.count }.from(0).to(1)
      end
    end

    context 'locale RU' do
      let(:customer) { create(:customer, language: 'ru') }
      let(:shop) { create(:shop, customer: customer) }

      let(:mail) { ErrorsMailer.yml_import_error(shop, 'REASON') }
      it 'renders' do
        expect(mail.to).to eq [customer.email]
        expect(mail.subject).to eq 'Неправильно указан YML файл'
        expect(mail.body.raw_source).to match 'К сожалению мы не смогли обработать YML-файл вашего интернет-магазина'
      end
    end

    context 'not notify for CMS' do
      let(:customer) { create(:customer, language: 'ru') }
      let(:shop) { create(:shop, customer: customer, yml_notification: false) }

      let(:mail) { ErrorsMailer.yml_import_error(shop, 'REASON') }
      it 'renders' do
        expect(mail.to).to eq ['support@rees46.com']
      end
    end
  end



  describe '#yml_url_not_respond' do
    context 'locale EN' do
      let(:customer) { create(:customer, language: 'en') }
      let(:shop) { create(:shop, customer: customer) }

      let(:mail) { ErrorsMailer.yml_url_not_respond(shop) }
      it 'renders' do
        expect(mail.subject).to eq 'Error in XML-file Load'
        expect(mail.to).to eq [customer.email]
        expect(mail.from).to eq ['support@rees46.com']
        expect(mail.header['List-Id'].value).to eq '<notification errors_mailer:yml_url_not_respond>'
        expect(mail.header['Feedback-ID'].value).to eq 'yml_url_not_respond:errors_mailer:rees46mailer'
        expect(mail.body.raw_source).to match 'Unfortunately, we could not load your XML Product Feed'
        ActionMailer::Base.deliveries = []
        expect { mail.deliver_now }.to change { ActionMailer::Base.deliveries.count }.from(0).to(1)
      end
    end

    context 'locale RU' do
      let(:customer) { create(:customer, language: 'ru') }
      let(:shop) { create(:shop, customer: customer) }

      let(:mail) { ErrorsMailer.yml_url_not_respond(shop) }
      it 'renders' do
        expect(mail.subject).to eq 'Не удалось загрузить YML-файл'
        expect(mail.body.raw_source).to match 'К сожалению мы не смогли загрузить YML-файл вашего интернет-магазина'
      end
    end
  end



  describe '#yml_syntax_error' do
    context 'locale EN' do
      let(:customer) { create(:customer, language: 'en') }
      let(:shop) { create(:shop, customer: customer) }

      let(:mail) { ErrorsMailer.yml_syntax_error(shop, 'MESSAGE') }
      it 'renders' do
        expect(mail.subject).to eq 'XML-file Syntax Error'
        expect(mail.to).to eq [customer.email]
        expect(mail.from).to eq ['support@rees46.com']
        expect(mail.header['List-Id'].value).to eq '<notification errors_mailer:yml_syntax_error>'
        expect(mail.header['Feedback-ID'].value).to eq 'yml_syntax_error:errors_mailer:rees46mailer'
        expect(mail.body.raw_source).to match 'XML-file due to error in syntax below'
        ActionMailer::Base.deliveries = []
        expect { mail.deliver_now }.to change { ActionMailer::Base.deliveries.count }.from(0).to(1)
      end
    end

    context 'locale RU' do
      let(:customer) { create(:customer, language: 'ru') }
      let(:shop) { create(:shop, customer: customer) }

      let(:mail) { ErrorsMailer.yml_syntax_error(shop, 'MESSAGE') }
      it 'renders' do
        expect(mail.subject).to eq 'Ошибка синтаксиса YML-файла'
        expect(mail.body.raw_source).to match 'мы не смогли обработать YML-файл'

      end
    end
  end



  describe '#yml_off' do
    context 'locale EN' do
      let(:customer) { create(:customer, language: 'en') }
      let(:shop) { create(:shop, customer: customer) }

      let(:mail) { ErrorsMailer.yml_off(shop) }
      it 'renders' do
        expect(mail.subject).to eq 'XML-file Load Is Off'
        expect(mail.to).to eq [customer.email]
        expect(mail.from).to eq ['support@rees46.com']
        expect(mail.header['List-Id'].value).to eq '<notification errors_mailer:yml_off>'
        expect(mail.header['Feedback-ID'].value).to eq 'yml_off:errors_mailer:rees46mailer'
        expect(mail.body.raw_source).to match ' we have not been able to load'
        ActionMailer::Base.deliveries = []
        expect { mail.deliver_now }.to change { ActionMailer::Base.deliveries.count }.from(0).to(1)
      end
    end

    context 'locale RU' do
      let(:customer) { create(:customer, language: 'ru') }
      let(:shop) { create(:shop, customer: customer) }

      let(:mail) { ErrorsMailer.yml_off(shop) }
      it 'renders' do
        expect(mail.subject).to eq 'Обработка YML-файла отключена'
        expect(mail.body.raw_source).to match 'в течение 5-ти дней.'
      end
    end
  end



  describe '#products_import_error' do
    context 'locale EN' do
      let(:customer) { create(:customer, language: 'en') }
      let(:shop) { create(:shop, customer: customer) }

      let(:mail) { ErrorsMailer.products_import_error(shop, 'MESSAGE') }
      it 'renders' do
        expect(mail.subject).to eq 'Products import error'
        expect(mail.to).to eq [customer.email]
        expect(mail.from).to eq ['support@rees46.com']
        expect(mail.header['List-Id'].value).to eq '<notification errors_mailer:products_import_error>'
        expect(mail.header['Feedback-ID'].value).to eq 'products_import_error:errors_mailer:rees46mailer'
        expect(mail.body.raw_source).to match 'Be sure to check your syntax against'
        ActionMailer::Base.deliveries = []
        expect { mail.deliver_now }.to change { ActionMailer::Base.deliveries.count }.from(0).to(1)
      end
    end

    context 'locale RU' do
      let(:customer) { create(:customer, language: 'ru') }
      let(:shop) { create(:shop, customer: customer) }

      let(:mail) { ErrorsMailer.products_import_error(shop, 'MESSAGE') }
      it 'renders' do
        expect(mail.subject).to eq 'Ошибка импорта товаров'
        expect(mail.body.raw_source).to match 'не смогли обработать импортированный список товаров'
      end
    end
  end
end
