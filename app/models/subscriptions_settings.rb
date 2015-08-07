##
# Настройки сбора e-mail. Создаются в rees46-rails
#
class SubscriptionsSettings < ActiveRecord::Base

  belongs_to :shop

  def readonly?
    true
  end

  def to_json
    super(only: [:enabled, :overlay, :header, :text])
  end

  def has_picture?
    picture_file_name.present?
  end

  def picture_url
    "#{Rees46.site_url}/subscription_picture/#{shop.uniqid}"
  end
end
