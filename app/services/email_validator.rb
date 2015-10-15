class EmailValidator

  attr_accessor :email

  def initialize(email)
    @email = email.to_s.strip
  end

  def validated_and_clean
    valid? ? email : nil
  end

  def valid?
    !email.match(/\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/).nil?
  end

end