class IncomingDataTranslator
  class << self
    def is_available?(value)
      if value != nil
        if (value == '1' || value == 1 || value == true || value == 'true')
          return true
        else
          return false
        end
      else
        return true
      end
    end

    def email_valid?(email)
      IncomingDataTranslator.email(email).present?
    end

    def email(email)
      if email.present?
        if email =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
          email.downcase.strip
        else
          nil
        end
      else
        nil
      end
    end
  end
end
