class People::Segmentation::SegmentWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  # @param [Segment|Integer] segment
  def perform(segment)

    # Если был передан id сегмента
    segment = Segment.find segment unless segment.is_a? Segment

    # @type [Shop] shop
    shop = segment.shop

    # Обновляем статистику по сегменту
    segment.update({
        updating: false,
        client_count: Slavery.on_slave { shop.clients.with_segment(segment.id).count },
        with_email_count: Slavery.on_slave { shop.clients.with_segment(segment.id).with_email.count },
        trigger_client_count: Slavery.on_slave { shop.clients.with_email.with_segment(segment.id).where(triggers_enabled: true).count },
        digest_client_count: Slavery.on_slave { shop.clients.with_email.with_segment(segment.id).where(digests_enabled: true).count },
        web_push_client_count: Slavery.on_slave { shop.clients.with_segment(segment.id).where(web_push_enabled: true).count },
    })
  end
end
