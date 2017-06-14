module StringHelper
  class << self
    def encode_and_truncate(string, length = 250)
      res = string.to_s
      res = res.gsub("\u0000", '')
      res = res.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
      res = res.truncate(length)
      res = res.strip
      res.present? ? res : nil
    end

    def format_money(value)
      ActiveSupport::NumberHelper.number_to_rounded(value, precision: 0, delimiter: "'")
    end
  end
end
