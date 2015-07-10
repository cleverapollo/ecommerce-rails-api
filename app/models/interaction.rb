##
# Действие пользователя
#
class Interaction < ActiveRecord::Base

  include UserLinkable

  CODES = {
                'view' => 1,
                'cart' => 2,
    'remove_from_cart' => 3,
            'purchase' => 4,
                'rate' => 5
  }

  RECOMMENDER_CODES = {
        'interesting' => 1,
            'similar' => 2,
           'see_also' => 3,
        'also_bought' => 4,
         'buying_now' => 5,
            'popular' => 6,
    'recently_viewed' => 7,
            'rescore' => 8,
       'trigger_mail' => 9,
        'digest_mail' => 10,
            'dating'  => 11,
      'experiment'  => 12
  }

  belongs_to :user
  belongs_to :shop
  belongs_to :item

  validates :user_id, presence: true
  validates :shop_id, presence: true
  validates :item_id, presence: true
  validates :code, presence: true

  class << self
    def push(opts = {})
      create!(
                 user_id: opts.fetch(:user_id),
                 shop_id: opts.fetch(:shop_id),
                 item_id: opts.fetch(:item_id),
                    code: CODES[opts.fetch(:type)],
        recommender_code: RECOMMENDER_CODES[opts[:recommended_by]]
      )
    end
  end
end
