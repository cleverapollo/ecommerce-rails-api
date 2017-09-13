# Что такое

Эксперимент с новыми алгоритмами для блочных рекомендеров. Работает с базой товаров в ElasticSearch, вместо того, чтобы лезть в PG.

Для работы пока принимает параметры ```Recommendations::Params```. Потом напишем свои.

Пример:

```
params = {shop: Shop.find_by_code('357382bf66ac0ce2f1722677c59511'), ssid: User.first, raw: {categories: '483'} }
rule = { type: 'recommender', recommender: 'popular' }
extracted_params = RecAlgo::Params.new(params, rule)
RecAlgo::Base.get_implementation_for(extracted_params.type).new(extracted_params).recommendations
```
