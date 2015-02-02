# Каждую полночь выключаем товары со "сроком годности"
every '0 0 * * * ' do
  runner 'Item.disable_expired'
end

# Каждую ночь в 2 часа синхронизируем YML
every '0 2 * * * ' do
  runner 'YmlWorker.process_all!'
end

# Каждую ночь в 4 часа выключаем корзины
every '0 4 * * *' do
  runner 'CartsExpirer.perform!'
end

every 30.minutes do
  runner 'BounceHandlerWorker.perform'
end

every 40.minutes do
  runner 'TriggerMailings::ClientsProcessor.process_all'
end
