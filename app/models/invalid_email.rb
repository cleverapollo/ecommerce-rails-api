class InvalidEmail < MasterTable

  validates :email, uniqueness: true, presence: true

  before_save :format_email

  private

  def format_email
    self.email = self.email.downcase.strip
  end
end