REES46 API
----------

![Codeship](https://www.codeship.io/projects/d543d470-be61-0131-e6b6-6ea1a21f61c4/status)

Back-end для приема событий и выдачи рекомендаций
=================================================

### Описание
Ядро REES46. Содержит в себе все алгоритмы расчета рекомендаций.

Делится на три основные части:

0. Инициализация пользователя

1. Прием событий. Из различных источников (JS, модули, SDK) к нам приходят данные о действиях пользователей в магазинах. Эти данные нужно обработать и сохранить.

2. Выдача рекомендаций. Для пользователей запрашиваются рекомендации по различным сценариям. Тут в дело вступает Apache Mahout.

3. Импорты. Заказы, товары, yandex market file.

### Внешние зависимости
* ruby-2.2.2
* PostgreSQL 9.4+
* Redis
* https://bitbucket.org/mkechinov/rees46_brb


### Развертывание
```
$ bundle
$ bin/rake db:create db:schema:load
$ foreman start
```

### Тесты
```
$ bin/rspec
```

### Структура шардов

Эти таблицы лежат также в шардах:
** actions
** clients
** items

Но, чтобы работала schema.rb и тесты, нужно делать обычные миграции, которые будут создавать структуру таблиц в основной базе, и мигратор для шардов, который будет менять таблицы товаров с данными в шардовых базах.

```
$ rake shards:migrate
$ rake shards:rollback
```

Чтобы это работало, кладете миграции как в каталог db/migrate, так и в каталог db/migrate/shards.