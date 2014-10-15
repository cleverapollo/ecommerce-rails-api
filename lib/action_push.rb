module ActionPush
  ##
  # Базовый класс ошибки при работе с событиями
  #
  class Error < StandardError; end

  ##
  # Ошибка входящих параметров при работе с событиями
  #
  class IncorrectParams < Error; end
end
