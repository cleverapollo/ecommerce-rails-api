class VendorCampaign < MasterTable
  belongs_to :shop
  belongs_to :shop_inventory
  belongs_to :currency
  validates :vendor_id, :shop_id, :currency_id, presence: true, numericality: { only_integer: true }
  validates :max_cpc_price, presence: true, numericality: { greater_than: 0 }
  validates :name, presence: true

  has_attached_file :image
  validates_attachment_content_type :image, content_type: /\Aimage/
  validates_attachment_file_name :image, matches: [/png\Z/i, /jpe?g\Z/i]

  enum status: [:draft, :moderation, :published, :declined, :stopped]

  default_scope -> { where(status: 2) }

  # Ищет продвигаемый товар среди предоставленных и, если такой есть,
  # возвращает его идентификатор для последующей постановки на первое место.
  # @param item_ids [Array]
  # @param discount [Boolean] Искать только по скидочным товарам
  # @return Integer
  def first_in_selection(item_ids, discount = false)
    Slavery.on_slave do
      relation = Item.recommendable.widgetable.where(id: item_ids, brand: brand).by_sales_rate.limit(1)
      relation = relation.discount if discount
      relation.pluck(:id).first
    end
  end

  def first_in_shop(excluded_ids = [], discount = false)
    Slavery.on_slave do
      relation = Item.recommendable.widgetable.where(shop_id: shop_id, brand: brand).where.not(id: excluded_ids).by_sales_rate.limit(1)
      relation = relation.discount if discount
      relation.pluck(:id).first
    end
  end

  # Записать в статистику информацию о показе за сегодняшнюю дату
  # @param [Recommendations::Params] params
  def track_view(params)
    begin
      ClickhouseQueue.actions({
          session_id: params.session.id,
          current_session_code: params.current_session_code,
          shop_id: params.shop.id,
          event: 'recone_view',
          object_type: self.class,
          object_id: id,
          recommended_by: params.type,
          referer: params.request.referer,
          useragent: params.request.user_agent,
      })
    rescue StandardError => e
      raise e unless Rails.env.production?
      Rollbar.error 'Clickhouse action insert error', e
    end
  end

end
