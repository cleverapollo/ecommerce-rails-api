class DataFixer
  class << self
    def fix_duplicated_actions(params = {})
      begin
        Redis.current.set('DataFixer.fix_duplicated_actions.state', nil)
        ActiveRecord::Base.logger = nil if params[:silent]

        state = {
          processed: 1,
          deleted: 0,
          process: 0,
          count: Action.count.to_f
        }

        checked_users = Set.new
        cycles = 0

        Action.select([:user_id, :id]).find_each(batch_size: 50_000) do |action|
          state[:process] = (state[:processed] / state[:count] * 100).round(2)

          unless checked_users.include?(action[:user_id])
            Action.select(:item_id).where(user_id: action[:user_id]).group(:item_id).having('COUNT(*) > 1').each do |fuckup_item|
              first = true

              Action.where(user_id: action[:user_id], item_id: fuckup_item[:item_id]).order('rating DESC').each do |action|
                if first
                  first = false
                  next
                end

                action.delete
                state[:deleted] += 1
              end
            end

            checked_users.add(action[:user_id])
          end

          state[:processed] += 1
          cycles += 1
          if cycles == 1000
            Redis.current.set('DataFixer.fix_duplicated_actions.state', state.to_json)
            cycles = 0
          end
        end
      rescue StandardError => e
        Redis.current.set('DataFixer.fix_duplicated_actions.state', e.inspect)
        raise e
      end
    end
  end
end
