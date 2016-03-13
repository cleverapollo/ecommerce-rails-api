module Integrations

  class EKomiError < StandardError;
  end

  class EKomiParamsError < EKomiError;
  end

  class EKomiResponseError < EKomiError;
  end

  class EKomi

    require 'net/http'

    attr_reader :id, :key, :api_url, :data_type

    def initialize(id, key)
      @id = id
      @key = key
      @api_url = 'http://api.ekomi.de/v3'
      @data_type = 'json'
    end

    def put_order(order_id)
      raise Integrations::EKomiParamsError.new("Incorrect order_id: #{order_id}") unless order_id.present?
      response = request('/putOrder', order_id: order_id, version: 'cust-1.0.0' )
      raise Integrations::EKomiResponseError.new("Feedback link in putOrder not found: #{response}") unless response['link'].present?
      response
    end

    private

    def request(method, params = {})
      uri = URI("#{api_url}#{method}")
      raise Integrations::EKomiParamsError.new("Incorrect request params: #{params}") unless params.is_a? Hash
      params[:auth] = auth
      params[:type] = data_type
      uri.query = URI.encode_www_form(params)
      begin
        result = Net::HTTP.get_response(uri)
      rescue
        raise Integrations::EKomiError.new("Request timeout for #{params}")
      end
      if result.is_a?(Net::HTTPSuccess)
        return JSON.parse(result.body)
      else
        raise Integrations::EKomiError.new(result)
      end
    end

    def auth
      "#{id}|#{key}"
    end

  end

end