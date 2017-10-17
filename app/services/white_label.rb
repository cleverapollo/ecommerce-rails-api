class WhiteLabel
  class << self

    def personaclick?
      WHITE_LABEL_PLATFORM && WHITE_LABEL_PLATFORM == 'personaclick'
    end

    def kameleoon?
      WHITE_LABEL_PLATFORM && WHITE_LABEL_PLATFORM == 'kameleoon'
    end

    def default?
      WHITE_LABEL_PLATFORM.nil? || WHITE_LABEL_PLATFORM.blank? || WHITE_LABEL_PLATFORM == 'rees46'
    end

    def api_domain
      return 'api.personaclick.com' if self.personaclick?
      return 'api.rees46.com'
    end

  end
end