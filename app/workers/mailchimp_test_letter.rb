class MailchimpTestLetter
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
    while api.get_batch(merge_fields_batch['id'],'status')['status'] != 'finished'
      sleep 5
      puts 'Merge fields batch pending...'
    end

    test_member = api.add_member_to_list(test_list['id'], client.email, recommendations_in_hash(trigger))
    api.update_campaign(native_campaign, test_list['id'])

    test_campaign = api.duplicate_campaign(params['campaign_id'])


    api.send_campaign(test_campaign['id'])

    while (api.get_campaign(test_campaign['id'],'status')['status'] != 'sent')
      sleep 5
      puts 'Sending...'
    end

    api.delete_campaign(test_campaign['id'])
    api.delete_list(test_list['id'])
  end

end
