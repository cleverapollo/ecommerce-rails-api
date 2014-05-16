class IncomingDataTranslator
  class << self
    def is_available?(value)
      if value.present?
        value == '1' || value == 1 || value == true || value == 'true'
      else
        return true
      end
    end
  end
end
