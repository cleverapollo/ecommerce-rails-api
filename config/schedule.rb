every '0 0 * * * ' do
  runner 'Item.disable_expired'
end

every '0 2 * * * ' do
  runner 'YmlSyncWorker.new.perform'
end
