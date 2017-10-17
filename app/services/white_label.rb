class WhiteLabel
  class << self

    def personaclick?
      defined?(WHITE_LABEL_PLATFORM) && WHITE_LABEL_PLATFORM == 'personaclick'
    end

    def kameleoon?
      defined?(WHITE_LABEL_PLATFORM) && WHITE_LABEL_PLATFORM == 'kameleoon'
    end

    def default?
      !defined?(WHITE_LABEL_PLATFORM) || WHITE_LABEL_PLATFORM.blank? || WHITE_LABEL_PLATFORM == 'rees46'
    end

    def api_domain
      return 'api.personaclick.com' if self.personaclick?
      return 'api.rees46.com'
    end

  end
end