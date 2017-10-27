module Mailings
  module Mailchimp
    class Api
      include HTTParty

      attr_accessor :base_url, :auth

      def initialize(api)
        zone = api.gsub(/([a-z0-9]+-)(us\d+)/, '\2')
        @base_url = "https://#{zone}.api.mailchimp.com/3.0"
        @auth = { username: 'anystring', password: api }
      end

      ## CAMPAIGNS ---------------------------------------------------------------

      def get_campaign(campaign_id, fields = '')
        self.class.get(
          "#{base_url}/campaigns/#{campaign_id}?fields=#{fields}",
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          }
        )
      end

      def duplicate_campaign(campaign_id)
        self.class.post(
          "#{base_url}/campaigns/#{campaign_id}/actions/replicate",
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          },
          timeout: 60
        )
      end

      def update_campaign(campaign, list_id, settings)
        self.class.patch(
          "#{base_url}/campaigns/#{campaign['id']}",
          body: {
            type: 'regular',
            recipients: {
              list_id: list_id
            },
            settings: {
              subject_line: settings.subject,
              reply_to: settings.shop.mailings_settings.send_from.match(/.+<(.+)>/)[1],
              from_name: settings.shop.name
            }
          }.to_json,
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          }
        )
      end

      def send_campaign(campaign_id)
        self.class.post(
          "#{base_url}/campaigns/#{campaign_id}/actions/send",
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          }
        )
      end

      def delete_campaign(campaign_id)
        self.class.delete(
          "#{base_url}/campaigns/#{campaign_id}",
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          }
        )
      end

      ## LIST ---------------------------------------------------------------

      def create_temp_list(shop, settings)
        self.class.post(
          "#{base_url}/lists",
          body: {
            name: 'Temp List',
            contact: {
              company: "Company",
              address1: "Address 1",
              address2: "Address 2",
              city: "London",
              state: "OX",
              zip: "30308",
              country: "UK"
            },
            permission_reminder: "Trigger mail.",
            campaign_defaults: {
              from_name: shop.name,
              from_email: shop.mailings_settings.send_from.match(/.+<(.+)>/)[1],
              subject: settings.subject,
              language: shop.customer.language
              },
            email_type_option: false
          }.to_json,
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          }
        )
      end

      def get_list(list_id, fields = '')
        self.class.get(
          "#{base_url}/lists/#{list_id}?fields=#{fields}",
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          }
        )
      end

      def delete_list(list_id)
        self.class.delete(
          "#{base_url}/lists/#{list_id}",
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          }
        )
      end

      def add_member_to_list(list_id, email, merge_fields)
        self.class.post(
          "#{base_url}/lists/#{list_id}/members",
          body: {
            email_address: email.strip.downcase,
            status: "subscribed",
            merge_fields: merge_fields
          }.to_json,
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          }
        )
      end

      def get_members(list_id, count = 10, offset = 0, status = '', fields = '')
        self.class.get(
          "#{base_url}/lists/#{list_id}/members?count=#{count}&offset=#{offset}&status=#{status}&fields=#{fields}",
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          }
        )
      end

      # MERGE FIELD ---------------------------
      def add_merge_field(list, name, tag = nil)
        self.class.post(
          "#{base_url}/lists/#{list}/merge-fields",
          body: {
            name: name,
            tag: tag,
            type: "text",
            options: {
              size: 2000
            }
          }.to_json,
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          }
        )
      end

      # Get ALL merge-fields from list
      def get_merge_fields(list, count = 10, fields = '')
        self.class.get(
          "#{base_url}/lists/#{list}/merge-fields?count=#{count}&fields=#{fields}",
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          }
        )
      end

      def delete_merge_field(list, merge_field_id)
        self.class.delete(
          "#{base_url}/lists/#{list}/merge-fields/#{merge_field_id}",
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          }
        )
      end

      # BATCHES ---------------------------------------------------------

      def create_batch(operations)
        self.class.post(
          "#{base_url}/batches",
          body: {
            operations: operations
          }.to_json,
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          }
        )
      end

      def get_batch(batch_id, fields = '')
        self.class.get(
          "#{base_url}/batches/#{batch_id}?fields=#{fields}",
          basic_auth: auth,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'REES46 Fetcher 1.0'
          }
        )
      end
    end
  end
end

