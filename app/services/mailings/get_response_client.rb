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
        response = send_request('campaigns', {'query[name]': 'rees46triggers'})
      rescue
        raise GetResponseApiUnavailableError
      end
      if response.present? && response.first.present? && response.first['campaignId'].present?
        @campaign = response.first['campaignId']
        return self
      else
        Rails.logger.debug response if Rails.env.development?
        Rollbar.warning(response) unless Rails.env.development?
        raise GetResponseApiUnavailableError
      end
    end

    # Ищет кастомное поле
    # @param [String] name
    def search_custom_field(name)
      response = send_request('custom-fields',  {'fields': 'name', 'perPage': 1000})
      if response.any?
        response.each do |r|
          if r['name'] == name
            return r['customFieldId']
          end
        end
      end

      # Поле не было найдено
      Rails.logger.debug response
      raise GetResponseApiError.new "Custom field #{name} was not found. Response count: #{response.size}"
    end

    # Добавляет контакт в кампанию триггерных рассылок и отмечает ему свойство сработавшего триггера
    def add_contact(email, trigger_type, trigger_mail_code)
      raise GetResponseApiNotPreparedError if @campaign.blank?

      # Пробуем найти кастомное поле
      trigger_type_field = search_custom_field("rees46_#{trigger_type}")

      begin
        response = send_request('contacts',  {'query[campaignId]': @campaign, 'query[email]': email})
        if response.any?
          # Обновить триггер
          user_id = response.first['contactId']
          send_post("contacts/#{user_id}", {customFieldValues: [{customFieldId: trigger_type_field, value: [trigger_mail_code]}]})
        else
          # Создать новый
          send_post('contacts', {campaign: {campaignId: @campaign}, email: email, customFieldValues: [{customFieldId: trigger_type_field, value: [trigger_mail_code]}]})
        end
      rescue StandardError => e
        raise GetResponseApiUnavailableError.new e.message
      end

    end


    private

    def send_request(method, params)
      uri = URI.parse("#{MailingsSettings::GETRESPONSE_API_URL}#{method}")
      uri.query = URI.encode_www_form(params)
      req = Net::HTTP::Get.new(uri, initheader = {'Content-Type' =>'application/json', 'X-Auth-Token' => "api-key #{@mailing_settings.getresponse_api_key}"})

      res = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.ssl_version = :SSLv3
        http.request req
      end
      if res.code.to_i == 200
        JSON.parse res.body
      else
        raise GetResponseApiError.new res.body
      end
    end

    def send_post(method, params)
      uri = URI.parse("#{MailingsSettings::GETRESPONSE_API_URL}#{method}")
      req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json', 'X-Auth-Token' => "api-key #{@mailing_settings.getresponse_api_key}"})
      req.body = params.to_json

      res = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.ssl_version = :SSLv3
        http.request req
      end
      if res.code.to_i == 200 || res.code.to_i == 202
        JSON.parse res.body
      else
        begin
          json = JSON.parse res.body
          unless [1002].include? json['code'].to_i
            raise GetResponseApiError.new res.body
          end
        rescue Exception => e
          raise GetResponseApiUnavailableError.new "#{e.message}: #{res.body}"
        end
        nil
      end
    end


  end
end
