reload!
params = {
  'shop_id' => 'c441abf5dc8c9f3a46f12af52f3148',
  'shop_secret' => 'c7b8f06243e90286caa18ba0ac948e5b',

  'send_from' => 'REES46 <noreply@rees46.com>',
  'subject' => 'Тестовая рассылка',
  'template' => 'Здрасьте, {{name}}! <br/> <b>Вот рекомендации:</b><hr/> {{recommendations}}. Можете отписываться: {{unsubscribe_url}}',

  'users' => [
    {
      'id' => '53519',
      'email' => 'vasya@example.com',
      'name' => 'Vasya',
      'unsubscribe_url' => 'http://google.com'
    },
    {
      'id' => '52592',
      'email' => 'petya@example.com',
      'name' => 'Petya',
      'unsubscribe_url' => 'http://ya.ru'
    }
  ],

  'items' => [
    { 'id' => '3980', 'template' => 'Item 3980 ' },
    { 'id' => '34548', 'template' => 'Item 34548 ' },
    { 'id' => '34562', 'template' => 'Item 34562 ' },
    { 'id' => '29485', 'template' => 'Item 29485 ' },
    { 'id' => '2281', 'template' => 'Item 2281 ' },
    { 'id' => '1379', 'template' => 'Item 1379 ' },
    { 'id' => '34565', 'template' => 'Item 34565 ' },
    { 'id' => '32192', 'template' => 'Item 32192 ' },
    { 'id' => '3715', 'template' => 'Item 3715 ' },
    { 'id' => '40073', 'template' => 'Item 40073 ' },
    { 'id' => '29796', 'template' => 'Item 29796 ' },
    { 'id' => '33826', 'template' => 'Item 33826 ' },
    { 'id' => '32127', 'template' => 'Item 32127 ' },
    { 'id' => '34753', 'template' => 'Item 34753 ' },
    { 'id' => '2260', 'template' => 'Item 2260 ' },
    { 'id' => '33588', 'template' => 'Item 33588 ' },
    { 'id' => '3909', 'template' => 'Item 3909 ' },
    { 'id' => '2616', 'template' => 'Item 2616 ' },
    { 'id' => '3588', 'template' => 'Item 3588 ' }
  ],

  'recommendations_limit' => '5'
}

puts Benchmark.measure { DigestMailerWorker.new.perform(params) }
