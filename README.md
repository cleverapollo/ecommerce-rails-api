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


### Тесты
```
$ bin/rspec
```

### Структура шардов

Эти таблицы лежат в шардах:
** actions
** items

Обязательные операции, которые должны быть выполнены на базе API:

```
CREATE OR REPLACE FUNCTION uuid_generate_v4()
  RETURNS uuid AS
'$libdir/uuid-ossp', 'uuid_generate_v4'
  LANGUAGE c VOLATILE STRICT
  COST 1;
  
CREATE OR REPLACE FUNCTION generate_next_item_id(OUT result bigint) AS $$
      DECLARE
      our_epoch bigint := 1314220021721;
      seq_id bigint;
      now_millis bigint;
      shard_id int := 5;
      BEGIN
        SELECT nextval('items_id_seq')::BIGINT % 1024 INTO seq_id;
        SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
        result := (now_millis - our_epoch) << 23;
        result := result | (shard_id << 10);
        result := result | (seq_id);
        END;
        $$ LANGUAGE PLPGSQL;
        
CREATE OR REPLACE FUNCTION generate_next_action_id(OUT result bigint) AS $$
      DECLARE
      our_epoch bigint := 1314220021721;
      seq_id bigint;
      now_millis bigint;
      shard_id int := 5;
      BEGIN
        SELECT nextval('actions_id_seq')::BIGINT % 1024 INTO seq_id;
        SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
        result := (now_millis - our_epoch) << 23;
        result := result | (shard_id << 10);
        result := result | (seq_id);
        END;
        $$ LANGUAGE PLPGSQL;
        
ALTER TABLE items ALTER COLUMN id TYPE BIGINT;
ALTER TABLE items ALTER COLUMN id SET DEFAULT generate_next_item_id();
ALTER TABLE items ALTER COLUMN id SET NOT NULL;
ALTER TABLE actions ALTER COLUMN id TYPE BIGINT;
ALTER TABLE actions ALTER COLUMN id SET DEFAULT generate_next_action_id();
ALTER TABLE actions ALTER COLUMN id SET NOT NULL;

```



>> Дальнейшее пока не актуально

Но, чтобы работала schema.rb и тесты, нужно делать обычные миграции, которые будут создавать структуру таблиц в основной базе, и мигратор для шардов, который будет менять таблицы товаров с данными в шардовых базах.

```
$ rake shards:migrate
$ rake shards:rollback
```

Чтобы это работало, кладете миграции как в каталог db/migrate, так и в каталог db/migrate/shards.

Не забыть прописать последнюю актуальную версию миграции, чтобы не выполнялись все миграции из очереди
ActiveRecord::Base.connection.assume_migrated_upto_version '20150703141624'