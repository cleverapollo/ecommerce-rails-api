#
# Коннектор для сервиса рекомендательной системы
# Описание протокола: recommender_proto/doc/protocol.md
# Требования к реализации:
#   - соединение по TCP
#   - хост должен быть параметризирован, т.к. возможен запуск сервиса на разных хостах
#   - порт должен быть параметризирован, т.к. возможен запуск сервиса на разных портах
#   - instance должен быть параметризирован какой нибудь уникальной строкой, идентифицирующей экземпляр клиента
#   - соединение постоянное
#   - сообщения передаются в виде JSON
#   - конец сообщения - \r\n\r\n
#   - в случае разрыва соединения коннектор должен пытаться подсоединиться заново
#   - в случае разрыва соединения основное приложение должно уметь работать без результатов этого сервиса
#
class RecommenderService

  class ResponseError < StandardError; end

  class << self

    def instance
      @instance ||= RecommenderService.new('api')
    end

  end

  #
  # тестирование сетевого соединения
  #
  def ping
    msg = {
      version: @version,
      client: @instance,
      name: 'ping',
    }
    send(msg)
  end

  #
  # зарегистрировать в базе данных взаимодействие пользователя и товара
  #   timestamp: int - timestamp в unix-формате
  #   shop: int - название магазина
  #   user: int - код пользователя
  #   item: int|list[int] - код или коды товаров
  #   event: str - код события, первый символ должен принимать одно из значений:
  #     v - view
  #     c - cart
  #     p - purchase
  #     r - remove from cart
  #
  def interaction(timestamp, shop, user, item, event)
    msg = {
      version: @version,
      client: @instance,
      name: 'interaction',
      args: {
        timestamp: timestamp,
        shop: shop,
        user: user,
        item: item,
        event: event,
      }
    }
    send(msg)
  end

  #
  # объединение пользователей
  #   shop: int - код магазина
  #   user1: int - код 1-го объединяемого пользователя
  #   user2: int - код 2-го объединяемого пользователя
  #
  def relink(shop, user1, user2)
    msg = {
      version: @version,
      client: @instance,
      name: 'relink',
      args: {
        shop: shop,
        user1: user1,
        user2: user2,
      }
    }
    send(msg)
  end

  #
  # получить рекомендации
  #   shop: int - код магазина, для которого необходимо получить рекомендации
  #   model: str - название модели, которую необходимо использовать.
  #     null - пустая модель, всегда возвращает пустой список рекомендаций
  #     popular - популярный товар (по количеству взаимодействий), не зависит от пользователя
  #     lightfm - факторизационная модель
  #   user: int - код пользователя, для которого необходимо получить рекомендации
  #   include: list[int] - (необязательно) рекомендации должны быть только из этого списка товаров, если отсутствует - рекомендации выбираются из всех товаров
  #   exclude: list[int] - (необязательно) в рекомендациях не должны содержаться товары из этого списка
  #   limit: int - количество вовзращаемых товаров
  #
  # Результат:
  #   список рекомендованных id товаров длиной не более limit.
  #
  def recommend(shop, model, user, include, exclude, limit)
    msg = {
      version: @version,
      client: @instance,
      name: 'recommend',
      args: {
        shop: shop,
        model: model,
        user: user,
        include: include,
        exclude: exclude,
        limit: limit,
      }
    }
    send(msg)
  end

  private

  #
  # создаем коннектор
  # @param [String] instance название клиента сервиса (для логирования и мониторинга)
  def initialize(instance)
    @version = '1.0'
    @instance = instance
  end

  # Получаем подключение к серверу
  # @return [TCPSocket]
  def connection
    @connection ||= TCPSocket.new(Rails.application.secrets.recommender_host, Rails.application.secrets.recommender_port)
  end

  #
  # посылаем json на tcp-сокет,
  # получаем ответ в виде json {"status": "OK"|"error", "result": <result>}
  # в случае ошибки (status = error) - логируем и/или выбрасываем исключение
  # в случае успеха (status = OK) - возвращаем result
  # @param [Hash] msg
  def send(msg)
    begin
      Timeout::timeout(0.2) {
        message = JSON.generate(msg)
        Rails.logger.debug "RS: #{message}"

        # Отправляем сообщение
        connection.puts message
        connection.puts "\r\n\r\n"

        # Ждем ответа
        response = JSON.parse(connection.gets)
        connection.gets
        if response['status'] == 'OK'
          return response['result']
        else
          raise ResponseError.new(JSON.generate(response))
        end
      }
    rescue Timeout::Error => e
      raise e if Rails.env.development?
      Rollbar.warn 'RecommenderService timeout', e
      return false
    end
  end
end
