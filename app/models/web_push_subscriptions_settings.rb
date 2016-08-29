class WebPushSubscriptionsSettings < ActiveRecord::Base

  belongs_to :shop

  has_attached_file :picture, styles: { original: '500x500>', main: '170>x', medium: '130>x', small: '100>x' }

  # Used in old version of init_server_string
  def to_json
    super(only: [:enabled, :overlay, :header, :text, :button, :agreement, :manual_mode])
  end

  # Used in old version of init_server_string
  def has_picture?
    picture_file_name.present?
  end

  # Returns URL to subscription image or nil
  # @return String|nil
  def remote_picture_url
    picture_file_name.present? ? "#{Rees46.site_url.gsub('http:', '')}#{picture.url(:original)}" : nil
  end

  #
  # def picture_url
  #   "#{Rees46.site_url}/web_push_subscription_picture/#{shop.uniqid}"
  # end

end
