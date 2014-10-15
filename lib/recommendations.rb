module Recommendations
  ##
  # Базовый класс ошибки при работе с рекомендациями
  #
  class Error < StandardError; end

  ##
  # Ошибка входящих параметров при запросе рекомендаций
  #
  class IncorrectParams < Error; end
end
