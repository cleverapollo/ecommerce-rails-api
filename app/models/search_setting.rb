class SearchSetting < ActiveRecord::Base

  validates :shop_id, :landing_page, :filter_position, presence: true
  validates :filter_position, inclusion: %w(left right none)
  belongs_to :shop

end
