##
# Настройки рассылок.
#
class MailingsSettings < ActiveRecord::Base

  MAILING_SERVICES = [['REES46', 0], ['GetResponse', 1], ['Optivo for MyToys', 2], ['MailChimp', 3]]
  MAILING_SERVICE_REES46 = 0
  MAILING_SERVICE_GETRESPONSE = 1
  MAILING_SERVICE_OPTIVO_MYTOYS = 2
  MAILING_SERVICE_MAILCHIMP = 3
  MAILING_SERVICE_OFSYS = 4

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

  # Проверяет, настроен ли внешний сервис рассылок MailChimp
  def external_mailchimp?
    mailing_service == MAILING_SERVICE_MAILCHIMP && mailchimp_api_key.present?
  end

  # Проверяет, настроен ли внешний сервис рассылок Ofsys
  def external_ofsys?
    mailing_service == MAILING_SERVICE_OFSYS
  end

  # Проверяет, используется ли Optivo для MyToys как сервис рассылок
  # Как бы костыль
  # @return Boolean
  def is_optivo_for_mytoys?
    mailing_service == MAILING_SERVICE_OPTIVO_MYTOYS
  end

  def template_liquid?
    template_type == TEMPLATE_LIQUID
  end

  # def fetch_logo_url
  #   self.logo.present? ? URI.join("#{Rees46.site_url}", self.logo.url).to_s : ''
  # end
end
