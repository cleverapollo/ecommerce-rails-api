Paperclip::Attachment.default_options.merge!(
  url: "/uploads/:class/:attachment/:id/:style/:basename.:extension",
  path: ":rails_root/public/uploads/:class/:attachment/:id/:style/:basename.:extension",
  default_url: 'missing.jpg'
)

require 'paperclip/media_type_spoof_detector'
module Paperclip
  class MediaTypeSpoofDetector
    def spoofed?
      false
    end
  end
end
