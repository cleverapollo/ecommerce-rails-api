class ImageDownloaderWorker
  include Sidekiq::Worker
  sidekiq_options retry: 1, queue: 'resize'
  require 'open-uri'

  class ImageDownloaderError < StandardError; end

  def perform(params)
    shop = Shop.find(params.fetch('shop_id'))

    dir = "#{Rails.root}/resized_images/#{shop.uniqid}"
    Dir.mkdir(dir) unless File.exists?(dir)

    params.fetch('items_images').each do |item|
      path = "#{dir}/#{item['id']}.jpg"
      if File.file?(path) && File.atime(path) > 7.days.ago
        mtime = File.mtime(path)
        File.utime(Time.now, mtime, path)
      else
        open(path, 'wb') do |file|
          file << open(item['image_url']).read
        end
      end
    end

  end
end
