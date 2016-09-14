module Mailings
  module Mailchimp
    class TriggersSender
      include Mailings::Mailchimp::Common

      attr_accessor :triggers, :api, :shop_id

      def initialize(triggers_to_send, api_key, shop_id)
        @triggers = triggers_to_send
        @api = Mailings::Mailchimp::Api.new(api_key)
        @shop_id = shop_id
      end

      def send_all
        triggers.keys.each do |trigger_name|
          one_type_triggers = triggers[trigger_name]
          trigger_settings = TriggerMailing.find_by(shop_id: shop_id, trigger_type: trigger_name.to_s)

          native_campaign = api.get_campaign(trigger_settings.mailchimp_campaign_id) # Темплейт трггера
          list = api.create_temp_list(native_campaign) # Создание временный список
          merge_fields_batch = api.create_batch(prepare_merge_fields_batch(list['id'], trigger_settings.amount_of_recommended_items, one_type_triggers[0].source_item.present?)) # Добавление переменных в список

          # Ждем пока добавление не пройдет
          while api.get_batch(merge_fields_batch['id'],'status')['status'] != 'finished'
            puts 'Merge fields batch pending...'
            sleep 5
          end

          # Заготовка добавление клиентов в список с рекомендациями
          members_arry = []
          one_type_triggers.each do |trigger|
            trigger.source_items = trigger.recommendations(trigger_settings.amount_of_recommended_items)

            member = {
              method: "PUT",
              path: "lists/#{list['id']}/members/#{Digest::MD5.hexdigest(trigger.client.email)}",
              body: {
                email_address: trigger.client.email,
                status_if_new: "subscribed",
                merge_fields: recommendations_in_hash(trigger, trigger_settings.image_width, trigger_settings.image_height)
              }.to_json
            }

            members_arry = members_arry + [member]
          end

          # Добавление клиенты в список
          members_to_list_batch = api.create_batch(members_arry)

          # Ждем пока добавление клиентов в список не пройдет
          while api.get_batch(members_to_list_batch['id'],'status')['status'] != 'finished'
            puts 'Clients adding to list batch pending...'
            sleep 5
          end

          # Темплейту триггера указиваем созданый список как список по умолчанию
          # потому что продублированый темплейт отказывается
          # принимать созданый список как список по умолчанию (косяк MailCimp)
          api.update_campaign(native_campaign, list['id'])

          # Дублируем темплейт триггера
          campaign = api.duplicate_campaign(trigger_settings.mailchimp_campaign_id)

          # Отправление данного триггера сразу всем пользователям которые должны получить триггер
          api.send_campaign(campaign['id'])

          # Ждем пока не отправили всем письма
          while (api.get_campaign(campaign['id'],'status')['status'] != 'sent')
            puts 'Sending...'
            sleep 5
          end

          # Удаление продублированого темплейта и временного списка
          api.delete_campaign(campaign['id'])
          api.delete_list(list['id'])

          # Обновление пользователей что им было отправлено триггер
          one_type_triggers.each do |trigger|
            trigger.client.update_columns(last_trigger_mail_sent_at: Time.now)
            trigger.client.update_columns(supply_trigger_sent: true) if trigger.class == TriggerMailings::Triggers::LowOnSupply
          end
        end
      end

      private

    end
  end
end
