# encoding: UTF-8

# Пересчитываем статистику магазинов за 14 дней
every '0 3 * * *' do
  runner "RunnerWrapper.run('ShopKPI.recalculate_all_for_last_period')"
end
# Пересчитываем статистику за сегодня
every '5 * * * *' do
  runner "RunnerWrapper.run('ShopKPI.recalculate_for_today')"
end
every '2 * * * *' do
  runner "RunnerWrapper.run('TriggerMailings::Statistics.recalculate_all')"
end
# Высчитываем статистику за прошлый месяц
every '3 0 1 * *' do
  runner "RunnerWrapper.run('TriggerMailings::Statistics.recalculate_prev_all')"
end
every '4 * * * *' do
  runner "RunnerWrapper.run('WebPush::Statistics.recalculate_all')"
end
# Высчитываем статистику за прошлый месяц
every '5 0 1 * *' do
  runner "RunnerWrapper.run('WebPush::Statistics.recalculate_prev_all')"
end

# Каждые сутки синхронизируем YML
every 26.minutes do
  runner "RunnerWrapper.run('Shop.import_yml_files')"
end

# Publish all reputations older than 2 days
every 14.minutes do
  runner "RunnerWrapper.run('ReputationPublisher.perform')"
end

# Каждую ночь в 4 часа выключаем корзины
every '0 4 * * *' do
  runner "RunnerWrapper.run('CartsExpirer.perform')"
end

# Выгружаем триггерные рассылки в Optivo для MyToys
every '0 * * * *' do
  runner "RunnerWrapper.run('TriggerMailings::OptivoMytoysLetter.sync')"
end

# Выгружаем дайджестные рассылки для MyToys
every '1 0 * * *' do
  runner "RunnerWrapper.run('DigestMailings::Mytoys.sync(10)')"
end

every 34.minutes do
  runner "RunnerWrapper.run('BounceHandlerWorker.perform')"
end

every '45 23 * * *' do
  runner "RunnerWrapper.run('BounceHandlerWorker.perform_feedback_loop')"
end

every 1.week do
  runner "RunnerWrapper.run('BounceHandlerWorker.cleanup')"
end

# Drop outdated abandoned carts
every '50 23 * * *' do
  runner "RunnerWrapper.run('ClientCart.clear_outdated')"
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

every 18.minutes do
  runner "RunnerWrapper.run('WebPush::TriggersProcessor.process_all')"
end

# Каждую ночь в 3 часа пересчитываем SalesRate
every '0 3 * * *' do
  runner "RunnerWrapper.run('SalesRateCalculator.perform')"
end



# Каждые 30 минут пересчитываем SalesRate для новых магазинов
every 33.minutes do
  runner "RunnerWrapper.run('SalesRateCalculator.perform_newbies')"
end

# Каждую ночь пересчитываем сегменты активных покупателей
every '0 23 * * *' do
  runner "RunnerWrapper.run('People::Segmentation::ActivityWorker.perform_all')"
end
# Пересчитываем динамические сегменты
every '57 * * * *' do
  runner "RunnerWrapper.run('People::Segmentation::DynamicCalculateWorker.perform_all_shops')"
end
