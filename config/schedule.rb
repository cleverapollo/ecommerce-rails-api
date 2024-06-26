# encoding: UTF-8

# whenever --set 'WHITE_LABEL_PLATFORM='personaclick'' --update-crontab
# if @set_variables.has_key?(:WHITE_LABEL_PLATFORM)
#   job_type :runner,  "cd :path && WHITE_LABEL_PLATFORM=:WHITE_LABEL_PLATFORM bin/rails runner -e :environment ':task' :output"
# end

# Пересчитываем статистику магазинов за 14 дней
every '0 3 * * *' do
  runner "RunnerWrapper.run('ShopKPI.recalculate_all_for_last_period')"
end
# Пересчитываем статистику за сегодня
every '35 * * * *' do
  runner "RunnerWrapper.run('ShopKPI.recalculate_for_today')"
end
every '2 * * * *' do
  runner "RunnerWrapper.run('TriggerMailings::Statistics.recalculate_all')"
end
# Высчитываем статистику за прошлый месяц
every '3 8 1 * *' do
  runner "RunnerWrapper.run('TriggerMailings::Statistics.recalculate_prev_all')"
end
every '4 * * * *' do
  runner "RunnerWrapper.run('WebPush::Statistics.recalculate_all')"
end
# Высчитываем статистику за прошлый месяц
every '5 8 1 * *' do
  runner "RunnerWrapper.run('WebPush::Statistics.recalculate_prev_all')"
end
# Статистика по завершенным дайджестам
every '6 0 * * *' do
  runner "RunnerWrapper.run('DigestMailings::Statistics.recalculate_all')"
end
every '7 * * * *' do
  runner "RunnerWrapper.run('DigestMailings::Statistics.recalculate_today')"
end

# Каждые сутки синхронизируем YML
every 26.minutes do
  runner "RunnerWrapper.run('Shop.import_yml_files')"
end

# Publish all reputations older than 2 days
every 14.minutes do
  runner "RunnerWrapper.run('ReputationPublisher.perform')"
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


# RTB JOBS

# Remove expired jobs
every '50 23 * * *', roles: :production_cron do
  runner "RunnerWrapper.run('Rtb::Broker.cleanup_expired')"
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


# Расписание для проверки и создания новых партиций
every 1.month do
  runner "RunnerWrapper.run('DataManager::Partition::User.check')"
end
every 1.month do
  runner "RunnerWrapper.run('DataManager::Partition::Client.check')"
end

every 1.hour do
  rake "suggested_keywords:generate"
end
