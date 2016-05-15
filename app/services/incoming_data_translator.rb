##
# Класс, обрабатывающий входящие данные.
# Т.к. данные приходят из множества модулей и SDK, иногда формат входящих данных различается.
#
class IncomingDataTranslator

  BAD_EMAILS = %w(test@mail.ru anonymous@somedomain.com)
  BAD_EMAIL_DOMAINS = %w(example.com)

  class << self
    # Обработка входящего параметра "доступен ли товар". По умолчанию true.
    # @param value [Object] входящий параметр
    # @return [Boolean] обработанное значение "доступен ли товар"
    def is_available?(value)
      if value != nil
        # Все эти значения считаем за "Доступен"
        if (value == '1' || value == 1 || value == true || value == 'true')
          return true
        else
          return false
        end
      else
        # Если значение не передано - считаем что "Доступен"
        return true
      end
    end

    # Проверка входящего email на валидность.
    # @param value [String] входящий e-mail
    # @return [Boolean] валиден ли e-mail
    def email_valid?(email)
      IncomingDataTranslator.email(email).present?
    end

    # Обработка входящего email - даункейс + обрезка пробелов.
    # @param value [String] входящий e-mail
    # @return [String] обработанный e-mail
    def email(email)
      if email.present? && email =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i && !BAD_EMAILS.include?(email.downcase) && !BAD_EMAIL_DOMAINS.map{|x| email.downcase.scan(x) }.flatten.compact.any?
        email.downcase.strip
      end
    end
  end
end
