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
* ruby-2.2.0
* PostgreSQL 9.4+
* Redis
* https://bitbucket.org/mkechinov/rees46_brb


### Развертывание

Для Debian:
```
# apt-get install libarchive-dev
```

Для mac OS X:
```
$ brew install libarchive
$ bundle config build.libarchive-ruby --with-opt-dir=$(brew --prefix libarchive)
```

```
$ bundle
$ bin/rake db:create db:schema:load
$ foreman start
```

### Специфичные файлы конфигурации

/config/application.yml - прописать переменную REES46_SHARD (двузначный номер - 00, 01, ...)
/config/secrets – прописать весь набор ключей, указанный в примере secrets.yml.example
/config/shards.yml – прописать доступ к мастер-базе (базе, где содержатся клиенты сервиса, магазины и т.д.

### Тесты
```
$ bin/rspec
```

