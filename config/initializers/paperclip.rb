Paperclip::Attachment.default_options.merge!(
  url: "/uploads/:class/:attachment/:id/:style/:basename.:extension",
  path: ":rails_root/public/uploads/:class/:attachment/:id/:style/:basename.:extension",
  default_url: 'missing.jpg'
)
