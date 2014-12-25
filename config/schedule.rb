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

# Каждые 30 минут каждого часа обрабатываем подписки
every '30 * * * * ' do
  runner 'TriggerMailings::SubscriptionsProcessor.process_all'
end
