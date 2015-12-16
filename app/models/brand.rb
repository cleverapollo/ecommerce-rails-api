class Brand < MasterTable

  before_save :lowercase_keyword

  validates :name, :keyword, presence: true, uniqueness: true

  def match?(s)
    (s =~ regexp).present?
  end

  def regexp
    @regexp ||= /\b#{keyword}\b/i
  end

  private

  def lowercase_keyword
    if keyword.nil?
      self.keyword = name.downcase
    else
      self.keyword.downcase!
    end
  end

end
