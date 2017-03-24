class Segment < MasterTable
  belongs_to :shop

  TYPE_CALCULATE = 0
  TYPE_DYNAMIC = 1
  TYPE_STATIC = 2

  validates :shop_id, :name, :segment_type, presence: true

  after_destroy :remove_segment_from_client

  class << self

    # Расчетный сегмент: ищет ранее созданный или создает новый
    # @param [Shop] shop
    # @param [String] name
    # @return [Segment]
    def find_calculated_segment(shop, name)
      Segment.find_or_create_by!(shop_id: shop.id, segment_type: TYPE_CALCULATE, name: name.upcase)
    end

  end

  # Получает список клиентов сегмента
  # @return [Array<Client>]
  def clients
    shop.clients.with_segment(self.id)
  end

  private

  # Убирает связь у клиента с удаленным сегментом
  # Если у клиента больше не остается сегментов, сохраняем как null
  def remove_segment_from_client
    self.clients.update_all("segment_ids = CASE COALESCE(array_length(array_remove(segment_ids, #{self.id}), 1), 0) WHEN 0 THEN NULL ELSE array_remove(segment_ids, #{self.id}) END")
  end
end