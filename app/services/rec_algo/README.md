# Что такое

Эксперимент с новыми алгоритмами для блочных рекомендеров. Работает с базой товаров в ElasticSearch, вместо того, чтобы лезть в PG.

Для работы пока принимает параметры ```Recommendations::Params```. Потом напишем свои.

Пример:

```
params = {shop_id: '357382bf66ac0ce2f1722677c59511', ssid: '123', recommender_type: 'popular', categories: '483', limit: 40, extended: 1 }
extracted_params = Recommendations::Params.extract(params)
RecAlgo::Base.get_implementation_for(extracted_params.type).new(extracted_params).recommendations
```