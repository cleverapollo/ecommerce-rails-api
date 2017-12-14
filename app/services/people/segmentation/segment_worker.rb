class People::Segmentation::SegmentWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  # @param [Segment|Integer] segment
  def perform(segment)

    # Если был передан id сегмента
    segment = Segment.find segment unless segment.is_a? Segment

    # @type [Shop] shop
    shop = segment.shop

    # Нужно выбрать и клиентов и email, т.к. динамические сегменты пишут только клиентам
    relation = shop.shop_emails.with_clients.where('shop_emails.segment_ids @> ARRAY[:segment] OR clients.segment_ids @> ARRAY[:segment]', segment: segment.id)

    # Обновляем статистику по сегменту
    Segment.where(id: segment.id).update_all({
        updated_at: Time.now,
        updating: false,
        client_count: relation.count + shop.clients.where(email: nil).with_segment(segment.id).count,
        with_email_count: relation.count,
        trigger_client_count: relation.where(triggers_enabled: true).count,
        digest_client_count: relation.where(digests_enabled: true).count,
        web_push_client_count: shop.clients.with_segment(segment.id).where(web_push_enabled: true).count,
    })
  end
end
