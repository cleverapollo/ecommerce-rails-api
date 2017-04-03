class MailchimpTestTriggerLetter
  include Sidekiq::Worker
  include Mailings::Mailchimp::Common
  sidekiq_options retry: 1, queue: 'mailing'

  def perform(params)
    params = JSON.parse(params)
    api = Mailings::Mailchimp::Api.new(params['api_key'])

    client = Client.find(params['client_id'])
    trigger = params['trigger_mailing_class'].constantize.new client
    trigger.generate_test_data!
    trigger_mailing = TriggerMailing.find_by(shop_id: trigger.shop.id, trigger_type: trigger.class.to_s.gsub(/\A(.+::)(.+)\z/, '\2').underscore.to_sym)

    return if trigger_mailing.mailchimp_campaign_id.blank?

    native_campaign = api.get_campaign(params['campaign_id'])
    return if native_campaign.is_a?(String) # TODO уведомлять клиента по почте что не указал правильный Сampaign ID


    test_list = api.create_temp_list(native_campaign)
    sleep 5
    merge_fields_batch = api.create_batch(prepare_merge_fields_batch(test_list['id'], trigger.source_items.count, trigger.source_item.present?))
    waiting_times = 0
    while api.get_batch(merge_fields_batch['id'],'status')['status'] != 'finished'
      raise NotImplementedError.new('Too long pending merge fields') if waiting_times > 6
      sleep 10
      puts 'Merge fields batch pending...'
      waiting_times += 1
    end

    test_member = api.add_member_to_list(test_list['id'],
                                         client.email,
                                         recommendations_in_hash(trigger.source_items,
                                                                 trigger.source_item,
                                                                 client.location,
                                                                 trigger.shop.currency, {},
                                                                 trigger_mailing.images_dimension))
    api.update_campaign(native_campaign, test_list['id'])

    test_campaign = api.duplicate_campaign(params['campaign_id'])

    sleep 5
    api.send_campaign(test_campaign['id'])

    waiting_times = 0
    while (api.get_campaign(test_campaign['id'],'status')['status'] != 'sent')
      raise NotImplementedError.new('Too long sending test letter') if waiting_times > 6
      sleep 10
      puts 'Sending...'
      waiting_times += 1
    end

    delete_camping_and_list(api, test_campaign['id'], test_list['id'])
    rescue NotImplementedError => ex
      api.delete_campaign(test_campaign['id']) if test_campaign.present?
      api.delete_list(test_list['id']) if test_list.present?
      Rollbar.warning(ex, shop_id: trigger.shop.id)
    rescue
      api.delete_campaign(test_campaign['id']) if test_campaign.present?
      api.delete_list(test_list['id']) if test_list.present?
      Rollbar.warning('MailchimpTestTriggerLetter', shop_id: trigger.shop.id)

  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end
end
