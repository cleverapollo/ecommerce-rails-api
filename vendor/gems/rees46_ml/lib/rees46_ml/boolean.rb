require "uri"

module Rees46ML
  class Boolean < Virtus::Attribute
    TRUE =  ['true', 't', :true, :t, true]
    FALSE = ['false', 'f', :false, :f, false]

    def coerce(value)
      return nil if value.nil?

      TRUE.include?(value) ? true : FALSE.include?(value) ? false : nil
    end
  end
end
