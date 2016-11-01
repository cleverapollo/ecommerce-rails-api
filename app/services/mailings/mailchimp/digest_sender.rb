module Mailings
  module Mailchimp
    class DigestSender

      attr_accessor :digest_mailing, :api

      def initialize(digest_mailing, api_key)
        @digest_mailing = digest_mailing
        @api = Mailings::Mailchimp::Api.new(api_key)
      end

      def send
        native_campaign = api.get_campaign(digest_mailing.mailchimp_campaign_id)
        return if native_campaign.blank? # TODO уведомлять клиента по почте что не указал правильный Сampaign ID

        # Отправление сразу всем пользователям
        api.send_campaign(digest_mailing.mailchimp_campaign_id)

        # Ждем пока не отправили всем письма
        waiting_times = 0
        while (api.get_campaign(digest_mailing.mailchimp_campaign_id,'status')['status'] != 'sent')
          raise if waiting_times > 6
          puts 'Sending...'
          sleep 10
          waiting_times += 1
        end
        digest_mailing.finish!

        member_fields_counter = api.get_list(digest_mailing.mailchimp_list_id, 'stats.merge_field_count')['stats']['merge_field_count']
        merge_fields = api.get_merge_fields(digest_mailing.mailchimp_list_id, 14, 'merge_fields.merge_id,merge_fields.tag')['merge_fields']

        merge_fields_tags = []

        (1..digest_mailing.amount_of_recommended_items).each do |counter|
          merge_fields_tags << "NAME#{counter}"
          merge_fields_tags << "URL#{counter}"
          merge_fields_tags << "PRICE#{counter}"
          merge_fields_tags << "IMAGE#{counter}"
        end

        merge_fields.each do |merge_field|
          if merge_fields_tags.include?(merge_field['tag'])
            api.delete_merge_field(digest_mailing.mailchimp_list_id, merge_field['merge_id'])
          end
        end
      end

    end
  end
end
