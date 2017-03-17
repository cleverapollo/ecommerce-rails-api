##
# Воркер, удаляющий связь клиента и сегмента.
# Удаляет сам сегмент окончательно
#
class SegmentDestroyWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'long'

  def perform(segment_id)
    return if segment_id.blank?

    # Ищем сегмент
    segment = Segment.find_by(id: segment_id)
    return if segment.nil?

    # Если сегмент не был помечен как удаляемый
    segment.update(deleted: true) unless segment.deleted?

    # Удаляем сегмент. Опеация зависит от количества клиентов в сегменте
    segment.destroy
  end
end
