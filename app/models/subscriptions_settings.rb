class SubscriptionsSettings < ActiveRecord::Base
  belongs_to :shop

  def readonly?
    true
  end

  def to_json
    super(only: [:enabled, :overlay, :header, :text])
  end
end
