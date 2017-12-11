class WhiteLabel
  class << self

    def personaclick?
      domain_name == 'personaclick'
    end

    def kameleoon?
      domain_name == 'kameleoon'
    end

    def default?
      domain_name == 'rees46'
    end

    def api_domain
      return 'api.personaclick.com' if self.personaclick?
      return 'api.rees46.com'
    end

    def master_domain
      return 'localhost:3000' if Rails.env.development?
      return 'personaclick.com' if self.personaclick?
      'rees46.com'
    end


    private

    def domain_name
      Rails.application.secrets.domain_name || 'rees46'
    end
  end
end
