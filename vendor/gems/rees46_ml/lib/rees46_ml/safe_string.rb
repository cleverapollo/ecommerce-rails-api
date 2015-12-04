module Rees46ML
  class SafeString < Virtus::Attribute
    def coerce(value)
      value ? value.to_s.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'}) : ''
    end
  end
end
