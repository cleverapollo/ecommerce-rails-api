module ActiveRecordExtension

  extend ActiveSupport::Concern

  module ClassMethods
    def each_batch_with_start_end_id(batch_size = 1000)
      offset = batch_size
      ids = get_start_end_ids(offset, batch_size)

      return if ids[:start_id].nil?

      while !ids[:end_id].nil?
        yield ids[:start_id], ids[:end_id]

        offset += batch_size
        ids = get_start_end_ids(offset, batch_size)
        return if ids[:start_id].nil?
      end
    end

    private

    def get_start_end_ids(offset, batch_size)
      start_id = order(:id).limit(1).offset(offset - batch_size).first.try(:id)
      end_id = order(:id).limit(1).offset(offset - 1).first.try(:id)
      end_id = order(:id).last.try(:id) if end_id.nil?
      { start_id: start_id, end_id: end_id }
    end
  end
end

# include the extension
ActiveRecord::Base.send(:include, ActiveRecordExtension)
