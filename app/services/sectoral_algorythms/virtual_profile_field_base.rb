module SectoralAlgorythms
  class VirtualProfileFieldBase

    attr_accessor :profile

    def initialize(profile)
      @profile = profile
    end

    def trigger_action(action, items)
      items.each { |item| trigger_view(item) } if action == 'view'
      items.each { |item| trigger_view(item) } if action == 'cart'

      items.each { |item| trigger_purchase(item) } if action== 'purchase'
    end

    def value
      raise NotImplementedError.new('This should be implemented in concrete Algorythm class')
    end

    def trigger_view(item)
      raise NotImplementedError.new('This should be implemented in concrete Algorythm class')
    end

    def trigger_purchase(item)
      raise NotImplementedError.new('This should be implemented in concrete Algorythm class')
    end

    def recalculate
      raise NotImplementedError.new('This should be implemented in concrete Algorythm class')
    end

    def attributes_for_update
      raise NotImplementedError.new('This should be implemented in concrete Algorythm class')
    end

    def merge(slave)
      raise NotImplementedError.new('This should be implemented in concrete Algorythm class')
    end

    def modify_relation(relation)
      relation
    end


    protected

    def merge_history(master_history, slave_history, &history_action)
      slave_history.merge(master_history) do |key, slave_value, master_value|
        result = nil
        if slave_value.nil?
          result = master_value
        else
          if master_value.nil?
            result = slave_value
          else
            if slave_value.is_a?(Hash)
              result =  merge_history(master_value, slave_value, &history_action)
            else
              result = history_action.call(master_value, slave_value)
            end
          end
        end
        result
      end
    end

  end
end