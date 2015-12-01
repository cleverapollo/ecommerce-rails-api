##
# Модуль с методами-хэлперами для работы с URL
#
class UrlParamsHelper
  class << self
    # Добавить параметры к URL
    # @param url [String] строка с URL
    # @param params = {} [Hash] параметры
    #
    # @return [String] URL с параметрами
    def add_params_to(url, params = {})
      require 'addressable/uri'
      result = Addressable::URI.parse(url).normalize.to_s
      params.each do |param_key, param_value|
        uri = URI.parse(result)
        result = if uri.query.present?
          new_query = URI.decode_www_form(uri.query) << [param_key, param_value]
          uri.query = URI.encode_www_form(new_query)
          uri.to_s
        else
          "#{uri}?#{param_key}=#{param_value}"
        end
      end
      result
    end
  end
end
