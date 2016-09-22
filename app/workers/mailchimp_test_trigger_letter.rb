class MailchimpTestTriggerLetter
  include Sidekiq::Worker
  include Mailings::Mailchimp::Common
  sidekiq_options retry: 5, queue: 'mailing'

  def perform(params)
    params = JSON.parse(params)
    api = Mailings::Mailchimp::Api.new(params['api_key'])

    client = Client.find(params['client_id'])
    trigger = params['trigger_mailing_class'].constantize.new client
    trigger.generate_test_data!


    native_campaign = api.get_campaign(params['campaign_id'])
    test_list = api.create_temp_list(native_campaign)
    merge_fields_batch = api.create_batch(prepare_merge_fields_batch(test_list['id'], trigger.source_items.count, trigger.source_item.present?))
    waiting_times = 0
    while api.get_batch(merge_fields_batch['id'],'status')['status'] != 'finished'
      raise if waiting_times > 6
      sleep 10
      puts 'Merge fields batch pending...'
      waiting_times += 1
    end

    trigger_mailing = TriggerMailing.find_by(shop_id: trigger.shop.id, trigger_type: trigger.class.to_s.gsub(/\A(.+::)(.+)\z/, '\2').underscore.to_sym)

    test_member = api.add_member_to_list(test_list['id'], client.email, recommendations_in_hash(trigger.source_items, trigger.source_item, client.location, trigger.shop.currency, {}, trigger_mailing.image_width, trigger_mailing.image_height))
    api.update_campaign(native_campaign, test_list['id'])

    # items, source_item, location, currency, utm_params = {}, width = nil, height = nil

    test_campaign = api.duplicate_campaign(params['campaign_id'])

    api.send_campaign(test_campaign['id'])

    waiting_times = 0
    while (api.get_campaign(test_campaign['id'],'status')['status'] != 'sent')
      if waiting_times > 6
        delete_camping_and_list(api, test_campaign['id'], test_list['id'])
        raise
      end
      sleep 10
      puts 'Sending...'
      waiting_times += 1
    end

    delete_camping_and_list(api, test_campaign['id'], test_list['id'])
  end
end
