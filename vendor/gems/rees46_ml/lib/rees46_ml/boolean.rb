require "uri"

module Rees46ML
  class Boolean < Virtus::Attribute
    TRUE =  Set.new(['true', 't', '1'])
    FALSE = Set.new(['false', 'f', '0'])

    def coerce(value)
      return nil if value.nil?
      s = value.to_s
      TRUE.include?(s) ? true : (FALSE.include?(s) ? false : nil)
    end
  end
end
