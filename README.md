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

### Структура БД

Распределение таблиц по серверам БД:
* Сайт
** потом решим
* API магазина
** actions
** clients
** items
** advertiser_item_categories - нет прямой связи с shop_id и редактируется на стороне магазина
** advertiser_purchases - используется и на сайте и в API. Больше на сайте, поэтому подумать.