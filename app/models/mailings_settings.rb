##
# Настройки рассылок.
#
class MailingsSettings < ActiveRecord::Base

  MAILING_SERVICES = [['REES46', 0], ['GetResponse', 1], ['Optivo for MyToys', 2]]
  MAILING_SERVICE_REES46 = 0
  MAILING_SERVICE_GETRESPONSE = 1
  MAILING_SERVICE_OPTIVO_MYTOYS = 2

  TEMPLATE_DEFAULT = 0
  TEMPLATE_LIQUID = 1

  belongs_to :shop

  validates :shop, presence: true
  validates :send_from, presence: true
  validates :template_type, presence: true, inclusion: {in: [0, 1]}

  has_attached_file :logo, styles: { original: '500x500>', main: '170>x', medium: '130>x', small: '100>x' }
  validates_attachment_content_type :logo, content_type: /\Aimage/
  validates_attachment_file_name :logo, matches: [/png\Z/i, /jpe?g\Z/i]

  def enabled?
    !shop.restricted?
  end

  # Проверяет, настроен ли внешний сервис рассылок GetResponse
  def external_getresponse?
    mailing_service == MAILING_SERVICE_GETRESPONSE && getresponse_api_key.present? && getresponse_api_url.present?
  end

  def template_liquid?
    template_type == TEMPLATE_LIQUID
  end

  def fetch_logo_url
    self.logo.present? ? URI.join("#{Rees46.site_url}", self.logo.url).to_s : ''
  end
end
