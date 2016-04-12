module Mailings
  class GetResponseClient

    class GetResponseApiError < StandardError; end
    class GetResponseApiUnavailableError < StandardError; end
    class GetResponseApiNotPreparedError < StandardError; end

    attr_accessor :shop, :mailing_settings, :campaign, :contact

    def initialize(shop)
      @shop = shop
      @mailing_settings = @shop.mailings_settings
      return false unless @mailing_settings.external_getresponse?

      # Готовим соединение
      # @connection = Jimson::Client.new(@mailing_settings.getresponse_api_url)

    end

    def prepare
      begin
        response = send_request('get_campaigns', {'name': {'EQUALS' => 'rees46triggers'}})
      rescue
        raise GetResponseApiUnavailableError
      end
      if response && response['result'].any? && response['result'].keys.first.present?
        @campaign = response['result'].keys.first
        return self
      else
        raise GetResponseApiUnavailableError
      end
    end

    # Добавляет контакт в кампанию триггерных рассылок и отмечает ему свойство сработавшего триггера
    def add_contact(email, trigger_type, trigger_mail_code)
      raise GetResponseApiNotPreparedError if @campaign.blank?
      trigger_type_field = "rees46_#{trigger_type}"

      response = send_request('get_contacts',  campaigns: [@campaign], 'email': {'EQUALS': email})
      if response && response['result'].class == Hash
        if response['result'].any? && response['result'].keys.any?
          # Обновить триггер
          user_id = response['result'].keys.first
          send_request('set_contact_customs',  contact: user_id, 'customs': [ {'name': "rees46_#{trigger_type}", 'content': trigger_mail_code} ])
        else
          # Создать новый
          send_request('add_contact', 'campaign': @campaign, 'email': email, 'customs': [ {'name': "rees46_#{trigger_type}", 'content': trigger_mail_code} ])
        end
      else
        raise GetResponseApiUnavailableError
      end

    end


    private

    def send_request(method, params)
      data = {
          jsonrpc: '2.0',
          method: method,
          params: [
              @mailing_settings.getresponse_api_key,
              params
          ],
          id: DateTime.now.strftime('%Q')
      }.to_json
      uri = URI.parse(@mailing_settings.getresponse_api_url)
      req = Net::HTTP::Post.new '/', initheader = {'Content-Type' =>'application/json'}
      req.body = data
      res = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.ssl_version = :SSLv3
        http.request req
      end
      JSON.parse res.body
    end


  end
end
