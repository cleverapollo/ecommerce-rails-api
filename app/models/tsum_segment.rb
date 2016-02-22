class TsumSegment < ActiveRecord::Base
  class << self
    def track(session, segment)
      begin
        find_or_create_by code: session, segment: segment
      rescue
      end
    end
  end
end
