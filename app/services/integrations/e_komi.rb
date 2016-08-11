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

    def put_order(order, product_ids = [])
      raise Integrations::EKomiParamsError.new("Incorrect order_id: #{order.inspect}") unless order.present?
      raise Integrations::EKomiParamsError.new("Incorrect products array: #{product_ids}") unless product_ids.is_a? Array
      response = request('/putOrder', order_id: order.uniqid, version: 'cust-1.0.0', product_ids: product_ids.join(',') )
      raise Integrations::EKomiResponseError.new("Feedback link in putOrder not found: #{response}") unless response['link'].present?
      response
    end


    def put_product(product_id, product_name, product_other = {})
      raise EKomiParamsError.new("Incorrect product_other argument: #{product_other.inspect}") unless product_other.is_a? Hash
      response = request('/putProduct', product_id: product_id, product_name: product_name.truncate(255), product_other: product_other.to_json, version: 'cust-1.0.0' )
      true
    end

    # Get latest feedback
    # @param options [Hash] - {range: ['1m', '6m', '1y'], fields: [date,feedback,rating] }
    # @return Array
    def get_feedback(options = {})
      options[:version] = 'cust-1.0.0'
      request('/getFeedback', options )
    end

    private

    def request(method, params = {})
      uri = URI("#{api_url}#{method}")
      raise Integrations::EKomiParamsError.new("Incorrect request params: #{params}") unless params.is_a? Hash
      params[:auth] = auth
      params[:type] = data_type
      params[:charset] = 'utf-8'
      uri.query = URI.encode_www_form(params)
      begin
        result = Net::HTTP.get_response(uri)
      rescue
        raise Integrations::EKomiError.new("Request timeout for #{params}")
      end
      if result.is_a?(Net::HTTPSuccess)
        begin
          return JSON.parse(result.body)
        rescue Exception => e
          Integrations::EKomiError.new(result)
        end
      else
        raise Integrations::EKomiError.new(result)
      end
    end

    def auth
      "#{id}|#{key}"
    end

  end

end
