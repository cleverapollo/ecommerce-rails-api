class MailchimpTestDigestLetter
  include Sidekiq::Worker
  include Mailings::Mailchimp::Common
  sidekiq_options retry: 5, queue: 'mailing'

  def perform(params)
    api = Mailings::Mailchimp::Api.new(params['api_key'])
    digest_mailing = DigestMailing.find(params.fetch('digest_mailing_id'))

    client = Client.find_by(email: params['test_email'], shop_id: digest_mailing.shop_id)
    if client.nil?
      begin
        client = Client.create!(shop_id: digest_mailing.shop_id, email: params['test_email'], user_id: User.create.id)
      rescue # Concurrency?
        client =  Client.find_by(email: params['test_email'], shop_id: sdigest_mailing.shop_id)
      end
    end

    native_campaign = api.get_campaign(digest_mailing.mailchimp_campaign_id)
    test_list = api.create_temp_list(native_campaign)

    DigestMailingRecommendationsCalculator.open(digest_mailing.shop, digest_mailing.amount_of_recommended_items) do |calculator|
      merge_fields_batch = api.create_batch(prepare_merge_fields_batch(test_list['id'], digest_mailing.amount_of_recommended_items))

      while api.get_batch(merge_fields_batch['id'],'status')['status'] != 'finished'
        sleep 5
        puts 'Merge fields batch pending...'
      end

      test_member = api.add_member_to_list(test_list['id'], client.email, recommendations_in_hash(calculator.recommendations_for(client.user), nil, client.location, digest_mailing.shop.currency, {}, digest_mailing.image_width, digest_mailing.image_height)) #####

      api.update_campaign(native_campaign, test_list['id'])
    end

    test_campaign = api.duplicate_campaign(digest_mailing.mailchimp_campaign_id)

    api.send_campaign(test_campaign['id'])

    waiting_times = 0
    while (api.get_campaign(test_campaign['id'],'status')['status'] != 'sent')
      raise if waiting_times > 6
      sleep 5
      puts 'Sending...'
      waiting_times += 1
    end

    api.delete_campaign(test_campaign['id'])
    api.delete_list(test_list['id'])

    api.update_campaign(native_campaign, digest_mailing.mailchimp_list_id)
  end

end
