class Action < ActiveRecord::Base
  TYPES = Dir.glob(Rails.root + 'app/models/actions/*').map{|a| a.split('/').last.split('.').first }

  class << self
    def get_factory(action_type)
      raise ArgumentError.new('Unsupported action type') unless TYPES.include?(action_type)

      action_implementation_class_name(action_type).constantize
    end

    def push(params)
      raise NotImplementedError.new('This method should be called on concrete action type class')
    end

    private

      def action_implementation_class_name(type)
        'Actions::' + type.split('_').map(&:capitalize).join
      end
  end
end
