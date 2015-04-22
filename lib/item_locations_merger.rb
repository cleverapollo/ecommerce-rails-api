##
# Умеет сливать объекты locations
#
module ItemLocationsMerger
  class << self
    def merge(old_locations, new_locations)
      return old_locations if new_locations.blank?

      result = old_locations.dup
      old_locations_to_remove = old_locations.dup

      if new_locations.is_a? Array
        new_locations.map(&:to_s).each do |key|
          if result[key].present?
            old_locations_to_remove.delete(key)
          else
            result[key] = { }
          end
        end
      elsif new_locations.is_a? Hash
        new_locations.stringify_keys!
        new_locations.each do |key, value|
          if result[key].present?
            old_locations_to_remove.delete(key)
          end

          result[key] = value
        end
      end

      old_locations_to_remove.keys.each do |key|
        result.delete(key)
      end

      result
    end
  end
end
