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
        self.class.get("#{base_url}/campaigns/#{campaign_id}?fields=#{fields}",
          headers: {'content-type' => 'application/json'},
          basic_auth: auth,
        )
      end

      def duplicate_campaign(campaign_id)
        self.class.post("#{base_url}/campaigns/#{campaign_id}/actions/replicate",
          headers: {'content-type' => 'application/json'},
          basic_auth: auth,
        )
      end

      def update_campaign(campaign, list_id)
        self.class.patch("#{base_url}/campaigns/#{campaign['id']}",
          headers: {'content-type' => 'application/json'},
          basic_auth: auth,
          body: {
            type: "regular",
            recipients: {
              list_id: list_id
            },
            settings: {
              subject_line: campaign['subject_line'],
              reply_to: campaign['reply_to'],
              from_name: campaign['from_name']
            }
          }.to_json
        )
      end

      def send_campaign(campaign_id)
        self.class.post("#{base_url}/campaigns/#{campaign_id}/actions/send",
          headers: {'content-type' => 'application/json'},
          basic_auth: auth
        )
      end

      def delete_campaign(campaign_id)
        self.class.delete("#{base_url}/campaigns/#{campaign_id}",
          headers: {'content-type' => 'application/json'},
          basic_auth: auth
        )
      end

      ## LIST ---------------------------------------------------------------

      def create_temp_list(default_camping)
        self.class.post("#{base_url}/lists",
          headers: {'content-type' => 'application/json'},
          basic_auth: auth,
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
            "permission_reminder":"You'\''re receiving this email because you signed up for updates about Freddie'\''s newest hats.",
            campaign_defaults: {
              from_name: default_camping['settings']['from_name'],
              from_email: default_camping['settings']['reply_to'],
              subject: default_camping['settings']['subject_line'],
              language: 'en'
              },
            email_type_option: true
          }.to_json

        )
      end

      def delete_list(list_id)
        self.class.delete("#{base_url}/lists/#{list_id}",
          headers: {'content-type' => 'application/json'},
          basic_auth: auth,
        )
      end

      def add_member_to_list(list_id, email, merge_fields)
        self.class.put("#{base_url}/lists/#{list_id}/members/#{Digest::MD5.hexdigest(email)}",
          headers: {'content-type' => 'application/json'},
          basic_auth: auth,
          body: {
            email_address: email,
            status_if_new: 'subscribed',
            merge_fields: merge_fields
          }.to_json
        )
      end

      def add_merge_field(list, name, tag = nil)
        self.class.post("#{base_url}/lists/#{list}/merge-fields",
          headers: {'content-type' => 'application/json'},
          basic_auth: auth,
          body: {
            name: name,
            tag: tag,
            type: "text",
            options: {
              size: 2000
            }
          }.to_json
        )
      end

      # BATCHES ---------------------------------------------------------

      def create_batch(operations)
        self.class.post("#{base_url}/batches",
          headers: {'content-type' => 'application/json'},
          basic_auth: auth,
          body: {
            operations: operations
          }.to_json
        )
      end

      def get_batch(batch_id, fields = '')
        self.class.get("#{base_url}/batches/#{batch_id}?fields=#{fields}",
          headers: {'content-type' => 'application/json'},
          basic_auth: auth
        )
      end
    end
  end
end

