# encoding: UTF-8
# Каждую полночь выключаем товары со "сроком годности"
every '0 0 * * *' do
  # runner "RunnerWrapper.run('Item.disable_expired')"
  rake 'products:disable_expired_products'
end

# Каждые 4 часа синхронизируем приоритетные YML
every 4.hours do
  # runner "RunnerWrapper.run('YmlWorker.process_priority')"
  rake 'yml:process_priority'
end

# Каждые сутки синхронизируем YML
every '0 2 * * *' do
  # runner "RunnerWrapper.run('YmlWorker.process_all')"
  rake 'yml:process_all'
end

# Каждую ночь в 4 часа выключаем корзины
every '0 4 * * *' do
  # runner "RunnerWrapper.run('CartsExpirer.perform')"
  rake 'products:expire_carts'
end

every 30.minutes do
  # runner "RunnerWrapper.run('BounceHandlerWorker.perform')"
  rake 'mailings:handle_bounces'
end

every 20.minutes do
  # runner "RunnerWrapper.run('TriggerMailings::ClientsProcessor.process_all')"
  rake 'mailings:trigger_process_all'
end

# Каждую ночь в 3 часа пересчитываем SalesRate
every '0 3 * * *' do
  # runner "RunnerWrapper.run('SalesRateCalculator.perform')"
  rake 'statistics:sales_rate'
end

# Каждые 30 минут пересчитываем SalesRate для новых магазинов
every 30.minutes do
  # runner "RunnerWrapper.run('SalesRateCalculator.perform_newbies')"
  rake 'statistics:sales_rate_newbies'
end

# Каждый день рассчитываем биллинг для рекламодателя
every '0 5 * * *' do
  # runner "RunnerWrapper.run('Promoting::Calculator.previous_days')"
  rake 'statistics:calculate_yesterday_promotion'
end

