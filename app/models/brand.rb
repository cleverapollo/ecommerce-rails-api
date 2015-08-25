class Brand < ActiveRecord::Base

  establish_connection MASTER_DB

  before_save :lowercase_keyword

  validates :name, :keyword, presence: true, uniqueness: true



  private

  def lowercase_keyword
    if keyword.nil?
      self.keyword = name.downcase
    else
      self.keyword.downcase!
    end
  end

end