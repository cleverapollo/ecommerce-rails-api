class Brand < ActiveRecord::Base

  establish_connection MASTER_DB

  before_save :lowercase_keyword

  validates :name, :keyword, presence: true



  private

  def lowercase_keyword
    keyword.downcase! unless keyword.nil?
  end

end
