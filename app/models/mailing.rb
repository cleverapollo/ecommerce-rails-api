class Mailing < ActiveRecord::Base
  belongs_to :shop

  validates :shop, presence: true
  validates :token, presence: true
  validates :delivery_settings, presence: true
  validates :items, presence: true

  store :delivery_settings, coder: JSON, accessors: [:send_from, :subject, :template, :recommendations_limit]
  serialize :items, JSON
  store :statistics

  after_initialize :assign_default_values, if: :new_record?
  #before_create :process_items

  has_many :mailing_batches

  def total_statistics
    result = {
      total: 0,
      with_recommendations: 0,
      no_recommendations: 0,
      failed: 0,
      duration: 0.0,
    }

    mailing_batches.find_each do |m_b|
      result.each do |key, _|
        result[key] += m_b.statistics[key]
      end
    end

    result
  end

  protected

  def assign_default_values
    loop do
      generated_token = SecureRandom.hex(8)
      if Mailing.where(token: generated_token).none?
        self.token = generated_token
        break
      end
    end
  end

  def process_items
    items.each do |item|
      item['internal_id'] = Item.find_by(shop_id: shop.id, uniqid: item['id']).try(:id)
    end
  end
end
