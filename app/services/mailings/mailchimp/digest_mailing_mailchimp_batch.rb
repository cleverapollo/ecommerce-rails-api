module Mailings
  module Mailchimp
    class DigestMailingMailchimpBatch
      include Mailings::Mailchimp::Common

      attr_accessor :batch, :api, :digest_mailing, :shop

      def initialize(batch, api_key)
        @batch = batch
        @api = Mailings::Mailchimp::Api.new(api_key)
        @digest_mailing = batch.mailing
        @shop = @digest_mailing.shop
      end

      def btach_execute
        # Добавление переменных в список
        merge_fields_batch = api.create_batch(prepare_merge_fields_batch(digest_mailing.mailchimp_list_id, digest_mailing.amount_of_recommended_items))

        # Ждем пока добавление не пройдет
        waiting_imes = 0
        while api.get_batch(merge_fields_batch['id'],'status')['status'] != 'finished'
          raise if waiting_imes > 6
          puts 'Merge fields batch pending...'
          sleep 5
          waiting_imes += 1
        end

        members_arry = []
        DigestMailingRecommendationsCalculator.open(shop, digest_mailing.amount_of_recommended_items) do |calculator|
          # Заготовка добавление клиентов в список с рекомендациями
          api.get_members(digest_mailing.mailchimp_list_id, batch.mailchimp_count, batch.mailchimp_offset, 'subscribed', 'members.email_address')['members'].each do |member|

            client = Client.find_by email: member['email_address'], shop_id: shop.id
            if client.nil?
              begin
                client = Client.create!(shop_id: shop.id, email: member['email_address'], user_id: User.create.id)
              rescue # Concurrency?
                client =  Client.find_by email: email, shop_id: shop.id
              end
            end

            digest_mail = @batch.digest_mails.create!(
              shop_id: batch.shop_id,
              client: client,
              mailing: batch.mailing
            ).reload

            track_email = Base64.encode64(client.try(:email).to_s)

            member = {
              method: "PUT",
              path: "lists/#{digest_mailing.mailchimp_list_id}/members/#{Digest::MD5.hexdigest(client.email)}",
              body: {
                email_address: client.email,
                status_if_new: "subscribed",
                merge_fields: recommendations_in_hash(calculator.recommendations_for(client.user), nil, client.location, shop.currency, digest_utm_params(track_email, digest_mail), digest_mailing.images_dimension)
              }.to_json
            }

            members_arry = members_arry + [member]
          end
        end

        # Обновление клиенты в список
        members_to_list_batch = api.create_batch(members_arry)

        # Ждем пока обновление клиентов в список не пройдет
        waiting_imes = 0
        while api.get_batch(members_to_list_batch['id'],'status')['status'] != 'finished'
          raise if waiting_imes > 6
          puts 'Clients adding to list batch pending...'
          sleep 20
          waiting_imes += 1
        end

        batch.complete!
      end

      def digest_utm_params(track_email, digest_mail = nil)
        {
          utm_source: 'rees46',
          utm_medium: 'digest_mail',
          utm_campaign: "digest_mail_#{Time.current.strftime("%d.%m.%Y")}",
          recommended_by: 'digest_mail',
          rees46_digest_mail_code: digest_mail.try(:code) || 'test',
          r46_merger: track_email
        }
      end

    end
  end
end
