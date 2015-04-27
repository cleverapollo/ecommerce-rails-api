def Mail(type)
  case type.to_sym
  when :trigger
    TriggerMail
  when :digest
    DigestMail
  end
end
