class WebPushSubscriptionsSettings < ActiveRecord::Base

  belongs_to :shop

  def to_json
    super(only: [:enabled, :overlay, :header, :text, :button, :agreement])
  end

  def has_picture?
    picture_file_name.present?
  end

  def picture_url
    "#{Rees46.site_url}/subscription_picture/#{shop.uniqid}"
  end

end
