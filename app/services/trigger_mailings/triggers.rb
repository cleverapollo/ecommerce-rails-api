module TriggerMailings
  module Triggers
    NAMES = %w(AbandonedCart RecentlyPurchased ViewedButNotBought AbandonedCategory AbandonedSearch Retention LowOnSupply ProductAvailable SecondAbandonedCart)
  end
end
# TriggerMailings::Triggers::NAMES.map{|x| "TriggerMailings::Triggers::#{x}" }.map(&:constantize).map { |x| [x.class_name, x.new(Client.first).priority] }.sort_by{|x| x[1]}.map {|x| puts "#{x[0]}:\t#{x[1]}"}
