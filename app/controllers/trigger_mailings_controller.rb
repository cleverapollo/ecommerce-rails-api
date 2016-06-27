##
# Контроллер, отвечающий за триггерные рассылки.
#
class TriggerMailingsController < ApplicationController
  include ShopAuthenticator

  # Запустить тестовую
  def send_test
    mailings_settings = MailingsSettings.find_by shop_id: @shop.id
    trigger_mailing = @shop.trigger_mailings.find_by trigger_type: params[:trigger_type]
    email = IncomingDataTranslator.email(params[:email])
    if email && mailings_settings && trigger_mailing && params[:trigger_type].present? && mailings_settings.template_liquid?

      trigger_mailing_class = "TriggerMailings::Triggers::#{params[:trigger_type].camelize}".constantize

      client = Client.find_by email: email, shop_id: @shop.id
      if client.nil?
        begin
          client = Client.create!(shop_id: @shop.id, email: email, user_id: User.create.id)
        rescue # Concurrency?
          client =  Client.find_by email: email, shop_id: @shop.id
        end
      end

      trigger = trigger_mailing_class.new client
      trigger.generate_test_data!
      TriggerMailings::Letter.new(client, trigger).send

    end
    render nothing: true, status: :ok
  end
end
