every '0 0 * * * ' do
  runner 'Item.disable_expired'
end

every '0 2 * * * ' do
  runner 'YmlSyncWorker.new.perform'
end

every '0 10 * * * ' do
  #runner 'TriggerMailings::SubscriptionsProcessor.process_all'
end
