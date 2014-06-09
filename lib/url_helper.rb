class UrlHelper
  class << self
    def add_param(url, param = {})
      param_key = param.keys[0].to_s
      param_value = param.values[0].to_s

      uri = URI.parse(url)
      if uri.query.present?
        new_query = URI.decode_www_form(uri.query) << [param_key, param_value]
        uri.query = URI.encode_www_form(new_query)
        uri.to_s
      else
        "#{uri}?#{param_key}=#{param_value}"
      end
    end
  end
end
