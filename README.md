REES46 API
----------

![Codeship](https://www.codeship.io/projects/d543d470-be61-0131-e6b6-6ea1a21f61c4/status)

Back-end для приема событий и выдачи рекомендаций
=================================================

### Описание
Ядро REES46. Содержит в себе все алгоритмы расчета рекомендаций.

Делится на две основные части:

1. Прием событий

2. Выдача рекомендаций

### Внешние зависимости
* ruby-2.1.1
* PostgreSQL 9.3+
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