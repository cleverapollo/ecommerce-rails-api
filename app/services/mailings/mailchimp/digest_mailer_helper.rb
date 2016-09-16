module Mailings
  module Mailchimp
    class DigestMailerHelper

      # attr_accessor :digest_mailing, :campaign_id, :list_id

      # def initialize(digest_mailing, api_key)
      #   @digest_mailing = digest_mailing
      #   @api = Mailings::Mailchimp::Api.new(api_key)
      #   @campaign_id = digest_mailing.mailchimp_campaign_id
      #   @list_id = digest_mailing.mailchimp_list_id
      # end

      class << self
        def all_audience(api_key, list_id)
          Mailings::Mailchimp::Api.new(api_key).get_list(list_id, 'stats.member_count')['stats']['member_count']
        end
      end

    end

  end
end


