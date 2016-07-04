# encoding: UTF-8

# Пересчитываем статистику магазинов за 14 дней
every '0 3 * * *' do
  runner "RunnerWrapper.run('ShopKPI.recalculate_all_for_last_period')"
end

# Каждые сутки синхронизируем YML
every 3.hour do
  runner "RunnerWrapper.run('Shop.import_yml_files')"
end

# Update shards mapping
every 10.minutes do
  runner "RunnerWrapper.run('Sharding::Shard.generate_nginx_mapping')"
end

# Каждую ночь в 4 часа выключаем корзины
every '0 4 * * *' do
  runner "RunnerWrapper.run('CartsExpirer.perform')"
end

# Выгружаем триггерные рассылки в Optivo для MyToys
every '0 * * * *' do
  runner "RunnerWrapper.run('TriggerMailings::OptivoMytoysLetter.sync')"
end

every 30.minutes do
  runner "RunnerWrapper.run('BounceHandlerWorker.perform')"
end

every 1.week do
  runner "RunnerWrapper.run('BounceHandlerWorker.cleanup')"
end

# Удаляем просроченные подписки на брошенные категории для триггеров
every '55 23 * * *' do
  runner "RunnerWrapper.run('TriggerMailings::SubscriptionForCategory.cleanup')"
end

# Удаляем просроченные подписки на товары для триггеров
every 1.month do
  runner "RunnerWrapper.run('TriggerMailings::SubscriptionForProduct.cleanup')"
end

every 20.minutes do
  runner "RunnerWrapper.run('TriggerMailings::ClientsProcessor.process_all')"
end

# Каждую ночь в 00:00 отправляем триггеры MyToys Optivo
every '0 0 * * *' do
  runner "RunnerWrapper.run('TriggerMailings::OptivoMytoysLetter.sync')"
end

# Каждую ночь в 3 часа пересчитываем SalesRate
every '0 3 * * *' do
  runner "RunnerWrapper.run('SalesRateCalculator.perform')"
end



# Каждые 30 минут пересчитываем SalesRate для новых магазинов
every 30.minutes do
  runner "RunnerWrapper.run('SalesRateCalculator.perform_newbies')"
end

# Каждую ночь пересчитываем сегменты активных покупателей
every '0 23 * * *' do
  runner "RunnerWrapper.run('People::Segmentation::ActivityWorker.perform_all')"
end
