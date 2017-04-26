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
      uri = URI.parse(result)
      query = (uri.query.present? ? Hash[URI.decode_www_form(uri.query)] : {}).deep_symbolize_keys
      params.each do |param_key, param_value|
        query = query.merge(Hash[param_key, param_value])
      end
      uri.query = URI.encode_www_form(query)
      uri.to_s
    end
  end
end
