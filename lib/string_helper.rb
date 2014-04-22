class StringHelper
  class << self
    def encode_and_truncate(string, length = 250)
      res = string.to_s
      res = res.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
      res = res.truncate(length)
      res
    end
  end
end