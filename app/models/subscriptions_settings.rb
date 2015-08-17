##
# Настройки сбора e-mail. Создаются в rees46-rails
#
class SubscriptionsSettings < ActiveRecord::Base
  DEFAULT_POPUP_CSS = File.read('app/assets/css/default_popup.css')

  after_initialize :assign_default_css, if: :new_record?
  before_validation :assign_default_css, if: :new_record?

  validates :css, presence: true

  belongs_to :shop

  def to_json
    super(only: [:enabled, :overlay, :header, :text])
  end

  def has_picture?
    picture_file_name.present?
  end

  def picture_url
    "#{Rees46.site_url}/subscription_picture/#{shop.uniqid}"
  end

  def assign_default_css
    self.css = DEFAULT_POPUP_CSS unless self.css.present?
  end
end
