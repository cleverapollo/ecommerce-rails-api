##
# Настройки сбора e-mail. Создаются в rees46-rails
#
class SubscriptionsSettings < ActiveRecord::Base

  establish_connection MASTER_DB

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
    host = Rails.env.development? ? 'localhost:3000' : 'rees46.com'
    "http://#{host}/subscription_picture/#{shop.uniqid}"
  end
end
