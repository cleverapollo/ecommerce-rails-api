##
# Настройки рассылок.
#
class MailingsSettings < ActiveRecord::Base

  belongs_to :shop

  validates :shop, presence: true
  validates :send_from, presence: true

  has_attached_file :logo, styles: { original: '500x500>', main: '170>x', medium: '130>x', small: '100>x' }
  validates_attachment_content_type :logo, content_type: /\Aimage/
  validates_attachment_file_name :logo, matches: [/png\Z/i, /jpe?g\Z/i]

  def enabled?
    !shop.restricted?
  end

  def fetch_logo_url
    self.logo.present? ? URI.join("http://#{ActionController::Base.asset_host}", self.logo.url).to_s : ''
  end
end
