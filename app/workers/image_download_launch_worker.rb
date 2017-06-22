class ImageDownloadLaunchWorker
  require 'bunny'
  include Sidekiq::Worker

  sidekiq_options retry: false, queue: 'resize'

  class ImageDownloadLaunchError < StandardError; end

  BATCH_SIZE = 50

  # Отправляет задачу в RabbitMQ на скачивание картинок.
  # https://bitbucket.org/mkechinov/rees46_pictures - как работает скрипт
  # @param shop_id - [Integer] - id магазина
  # @param items_images - [Array[ {id: item_id, image_url: item_image}, ... ] - масив хешов в которых записано id товара и url кратинки товара
  # @param delete_before_download - [Boolean] - если true тогда обязательно удаляем старую картинку и качаем ту которая указана в image_url
  def perform(shop_id, items_images = nil, delete_before_download =  false)
    @shop = Shop.find(shop_id)
    @delete_before_download = delete_before_download

    if items_images
      send_batch(items_images)
    else
      fetch_and_send_baches
    end


  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end

  private

  def initialized_connection
    return Bunny.new unless Rails.env.production?
    Bunny.new(host: '148.251.91.107', user: 'rees46', pass: Rails.application.secrets.bunny_password)
  end

  def connect!
    @connection = initialized_connection
    @connection.start
    @channel = @connection.create_channel
    @queue = @channel.queue('resize', durable: true)
  end

  def disconnect!
    @connection.close
  end

  def fetch_and_send_baches
    items_images = []

    Item.widgetable.where(shop_id: @shop.id).select(:id, :image_url).find_each do |item|
      items_images << { id: item.id, image_url: item.image_url }

      if items_images.size == BATCH_SIZE
        send_batch(items_images)
        items_images = []
      end
    end

    send_batch(items_images)
  end

  def send_batch(items_images)
    connect!
    @channel.default_exchange.publish({ shop_uniqid: @shop.uniqid,
                                        items_images: items_images,
                                        delete_before_download: @delete_before_download
                                      }.to_json,
                                      durable: true,
                                      routing_key: @queue.name)
    disconnect!
  end
end
