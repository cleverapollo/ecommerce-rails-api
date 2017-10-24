class SearchQueryRedirect < ActiveRecord::Base
  belongs_to :shop

  validates :shop_id, :query, :redirect_link, presence: true
  validates :query, uniqueness: { scope: :shop }
  validates_format_of :redirect_link, with: /\A(http|https):\/\/[^\s]+/ix

  scope :by_query, -> (query) { where(query: query) }

  def query= query
    super(query.try(:downcase))
  end

end
