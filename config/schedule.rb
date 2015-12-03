# encoding: UTF-8

# Пересчитываем статистику магазинов за 14 дней
every '0 3 * * *' do
  runner "RunnerWrapper.run('ShopKPI.recalculate_all_for_last_period')"
end



# # Каждые 4 часа синхронизируем приоритетные YML
# every 4.hours do
#   runner "RunnerWrapper.run('YmlWorker.process_priority')"
# end

# Каждые сутки синхронизируем YML
every 45.minutes do
  runner "RunnerWrapper.run('Shop.import_yml_files')"
end

# Каждую ночь в 4 часа выключаем корзины
every '0 4 * * *' do
  runner "RunnerWrapper.run('CartsExpirer.perform')"
end

every 30.minutes do
  runner "RunnerWrapper.run('BounceHandlerWorker.perform')"
end

every 1.week do
  runner "RunnerWrapper.run('BounceHandlerWorker.cleanup')"
end

every 20.minutes do
  runner "RunnerWrapper.run('TriggerMailings::ClientsProcessor.process_all')"
end

# Каждую ночь в 3 часа пересчитываем SalesRate
every '0 3 * * *' do
  runner "RunnerWrapper.run('SalesRateCalculator.perform')"
end

# Каждые 30 минут пересчитываем SalesRate для новых магазинов
every 30.minutes do
  runner "RunnerWrapper.run('SalesRateCalculator.perform_newbies')"
end


