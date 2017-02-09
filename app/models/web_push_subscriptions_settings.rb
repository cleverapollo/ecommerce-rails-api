class WebPushSubscriptionsSettings < ActiveRecord::Base

  DEFAULT_SERVICE_WORKER_PATH = '/push_sw.js'

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

  def safari_enabled?
    self.safari_website_push_id.present? && self.certificate_password.present? && self.certificate_updated_at.present? && self.pem_content.present?
  end

  def service_worker
    self.service_worker_path || DEFAULT_SERVICE_WORKER_PATH
  end

  # Configure safari web pusher for shop
  def safari_config

    return nil if pem_content.blank?

    # extract certificate
    file = "#{Rails.root}/tmp/safari_keys/#{shop_id}.pem"
    File.open(file, 'w') do |f|
      f.write pem_content
    end

    # initialize connection
    Grocer.pusher(
        certificate: file,
        passphrase: '',
        gateway: 'gateway.push.apple.com',
        port: 2195,
        retries: 3
    )
  end
end
