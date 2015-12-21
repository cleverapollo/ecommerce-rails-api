module TempFiles
  extend ActiveSupport::Concern

  def temp_file
    Tempfile.open(Time.now.to_i.to_s) { |file| yield file }
  end

  def csv_file(file, options = {})
    CSV.open(file.path, "wb", options) { |csv| yield csv }
  end
end
