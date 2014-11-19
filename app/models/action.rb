class Action < ActiveRecord::Base
  belongs_to :user
  belongs_to :item
  belongs_to :shop

  TYPES = Dir.glob(Rails.root + 'app/models/actions/*').map{|a| a.split('/').last.split('.').first }

  scope :by_average_rating, -> { order('AVG(rating) DESC') }
  scope :available, -> { where(is_available: true) }
  scope :in_locations, ->(locations) {
    if locations && locations.any?
      where("? <@ locations", "{#{locations.join(',')}}")
    end
  }

  scope :views, -> { where('rating::numeric = ?', Actions::View::RATING) }
  scope :carts, -> { where('rating::numeric = ?', Actions::Cart::RATING) }


  class << self
    def get_implementation_for(action_type)
      raise ActionPush::Error.new('Unsupported action type') unless TYPES.include?(action_type)

      action_implementation_class_name(action_type).constantize
    end

    def mass_process(params)
    end

    private

    def action_implementation_class_name(type)
      'Actions::' + type.camelize
    end
  end

  def process(params)
    update_concrete_action_attrs
    update_rating_and_last_action(params.rating) if needs_to_update_rating?
    set_recommended_by(params.recommended_by) if params.recommended_by.present?
    begin
      save
      post_process
      save_to_mahout if self.rating >= 3.7
    rescue ActiveRecord::RecordNotUnique => e
      # Action already saved
    end
  end

  def name_code
    self.class.to_s.split(':').last.underscore
  end

  def post_process

  end

  def update_concrete_action_attrs
    raise NotImplementedError.new('This method should be called on concrete action type class')
  end

  def update_rating_and_last_action(rating)
    raise NotImplementedError.new('This method should be called on concrete action type class')
  end

  def needs_to_update_rating?
    raise NotImplementedError.new('This method should be called on concrete action type class')
  end

  def set_recommended_by(recommended_by)
    self.recommended_by = recommended_by
  end

  def save_to_mahout
    MahoutAction.find_or_create_by(user_id: user.id, item_id: item.id, shop_id: shop.id)
  end
end
