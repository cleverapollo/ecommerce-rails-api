class Subdomain
  def self.matches?(request)
    request.subdomain.present? && request.subdomains.size > 1 && request.subdomains.reverse[0] == 'push'
  end
end