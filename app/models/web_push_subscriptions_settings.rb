class WebPushSubscriptionsSettings < ActiveRecord::Base

  belongs_to :shop

  has_attached_file :picture, styles: { original: '500x500>', main: '170>x', medium: '130>x', small: '100>x' }

  def to_json
    super(only: [:enabled, :overlay, :header, :text, :button, :agreement])
  end

  def has_picture?
    picture_file_name.present?
  end
  #
  # def picture_url
  #   "#{Rees46.site_url}/web_push_subscription_picture/#{shop.uniqid}"
  # end

end
