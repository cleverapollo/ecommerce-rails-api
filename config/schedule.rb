# Каждую полночь выключаем товары со "сроком годности"
every '0 0 * * * ' do
  runner "RunnerWrapper.run('Item.disable_expired')"
end

# Каждые 2 часа синхронизируем YML
every 2.hours do
  runner "RunnerWrapper.run('YmlWorker.process_all')"
end

# Каждую ночь в 4 часа выключаем корзины
every '0 4 * * *' do
  runner "RunnerWrapper.run('CartsExpirer.perform')"
end

every 30.minutes do
  runner "RunnerWrapper.run('BounceHandlerWorker.perform')"
end

every 40.minutes do
  runner "RunnerWrapper.run('TriggerMailings::ClientsProcessor.process_all')"
end
