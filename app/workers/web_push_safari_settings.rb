require 'push_package'

class WebPushSafariSettings
  include Sidekiq::Worker

  attr_reader :shop

  ICON_SETTINGS = [
    { name: 'icon_16x16.png', size: '16x16' },
    { name: 'icon_16x16@2x.png', size: '16x16' },
    { name: 'icon_32x32.png', size: '32x32' },
    { name: 'icon_32x32@2x.png', size: '32x32' },
    { name: 'icon_128x128.png', size: '128x128' },
    { name: 'icon_128x128@2x.png', size: '128x128' }
  ]

  def perform(shop_id)
    @shop = Shop.find(shop_id)

    website_params = {
      websiteName: "Rees46",
      websitePushID: "web.com.rees46",
      allowedDomains: [ shop.url ],
      urlFormatString: "#{shop.url}/%@/?flight=%@",
      authenticationToken: "19f8d7a6e9fb8a7f6d9330dabe",
      webServiceURL: "http://rees46.dm"
    }


    iconset_path = "public/webpush_safari_files/#{shop.id}"
    refresh_icons(iconset_path)

    certificate = 'webpush_safari_files/website_aps_production.p12' # or certificate_string
    intermediate_cert = 'webpush_safari_files/website_aps_production.cer'

    package = PushPackage.new(website_params, iconset_path, certificate, '976431976431', intermediate_cert)

    package.save("public/webpush_safari_files/#{shop.uniqid}.zip")
    FileUtils.rm_rf(iconset_path)
    package
  end

  def refresh_icons(iconset_path)
    FileUtils.mkdir_p(iconset_path) unless File.directory?(iconset_path)

    logo = MailingsSettings.find_by(shop_id: shop.id).logo
    logo_url = Rails.env.production? ? "https://rees46.com#{logo.url}" : "http://localhost:3000#{logo.url}"

    ICON_SETTINGS.each do |icon|
      image = MiniMagick::Image.open(logo_url)
      image.resize(icon[:size])
      image.format "png"
      image.write "#{iconset_path}/#{icon[:name]}"
    end
  end
end
