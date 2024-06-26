module Mailings
  module Mailchimp
    class TriggersSender
      class MailchimpTriggersSender < StandardError; end
      include Mailings::Mailchimp::Common

      attr_accessor :triggers, :api, :shop_id

      def initialize(triggers_to_send, api_key, shop_id)
        @triggers = triggers_to_send
        @api = Mailings::Mailchimp::Api.new(api_key)
        @shop_id = shop_id
      end

      def send_all
        triggers.keys.each do |trigger_name|
          begin
            one_type_triggers = triggers[trigger_name]
            trigger_settings = TriggerMailing.find_by(shop_id: shop_id, trigger_type: trigger_name.to_s)

            next if trigger_settings.mailchimp_campaign_id.blank? # TODO уведомлять клиента по почте

            native_campaign = api.get_campaign(trigger_settings.mailchimp_campaign_id) # Темплейт трггера
            next if native_campaign.is_a?(String) # TODO уведомлять клиента по почте

            list = api.create_temp_list(Shop.find(shop_id), trigger_settings) # Создание временный список
            sleep 5
            merge_fields_batch = api.create_batch(prepare_merge_fields_batch(list['id'], trigger_settings.amount_of_recommended_items, one_type_triggers[0].source_item.present?)) # Добавление переменных в список

            # Ждем пока добавление не пройдет
            waiting_imes = 0
            while api.get_batch(merge_fields_batch['id'],'status')['status'] != 'finished'
              raise MailchimpTriggersSender.new('Merge fields batch') if waiting_imes > 6
              sleep 5
              waiting_imes += 1
            end

            # Заготовка добавление клиентов в список с рекомендациями
            members_arry = []
            one_type_triggers.each do |trigger|
              trigger.source_items = trigger.recommendations(trigger_settings.amount_of_recommended_items)

              trigger_mail = trigger.client.trigger_mails.create!(
                mailing: trigger.mailing,
                shop_id: shop_id,
                trigger_data: {
                  trigger: trigger.to_json
                }
              ).reload

              member = {
                method: "PUT",
                path: "lists/#{list['id']}/members/#{Digest::MD5.hexdigest(trigger.client.email)}",
                body: {
                  email_address: trigger.client.email,
                  status_if_new: "subscribed",
                  merge_fields: recommendations_in_hash(trigger.source_items, trigger.source_item, trigger.client.location, trigger.shop.currency, Mailings::Composer.utm_params(trigger_mail), trigger_settings.images_dimension)
                }.to_json
              }

              members_arry = members_arry + [member]
            end

            # Добавление клиенты в список
            members_to_list_batch = api.create_batch(members_arry)

            # Ждем пока добавление клиентов в список не пройдет
            waiting_imes = 0
            while api.get_batch(members_to_list_batch['id'],'status')['status'] != 'finished'
              raise MailchimpTriggersSender.new('Members to list batch') if waiting_imes > 6
              sleep 10
              waiting_imes += 1
            end

            # Темплейту триггера указиваем созданый список как список по умолчанию
            # потому что продублированый темплейт отказывается
            # принимать созданый список как список по умолчанию (косяк MailCimp)
            result = api.update_campaign(native_campaign, list['id'], trigger_settings)
            raise MailchimpTriggersSender.new(result) if result.is_a?(String)

            # Дублируем темплейт триггера
            campaign = api.duplicate_campaign(trigger_settings.mailchimp_campaign_id)

            # Отправление данного триггера сразу всем пользователям которые должны получить триггер
            result_sending = api.send_campaign(campaign['id'])
            raise MailchimpTriggersSender.new(result_sending) if result_sending.is_a?(String)

            # Ждем пока не отправили всем письма
            waiting_times = 0
            while (api.get_campaign(campaign['id'],'status')['status'] != 'sent')
              if waiting_times > 6
                delete_camping_and_list(api, campaign['id'], list['id'])
                raise
              end
              sleep 10
              waiting_times += 1
            end

            # Удаление продублированого темплейта и временного списка
            delete_camping_and_list(api, campaign['id'], list['id'])

            # Обновление пользователей что им было отправлено триггер
            one_type_triggers.each do |trigger|
              trigger.client.update_columns(last_trigger_mail_sent_at: Time.now)
              trigger.client.update_columns(supply_trigger_sent: true) if trigger.class == TriggerMailings::Triggers::LowOnSupply
            end
          rescue => e
            api.delete_campaign(campaign['id']) if campaign.present?
            api.delete_list(list['id']) if list.present?
            sleep 5

            Rollbar.warning("MailchimpTriggerLetter: #{e}", shop_id: @shop_id)
          end
        end

      end

    end
  end
end
