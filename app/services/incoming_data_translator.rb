class IncomingDataTranslator
  class << self
    def is_available?(value)
      if value.present?
        value == '1' || value == 1 || value == true || value == 'true'
      else
        return true
      end
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
