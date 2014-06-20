Redis.new.flushall

MailerJob.delete_all

reload!

shop = Shop.find(1)

items = ["750", "471", "2094", "7336", "744", "488", "497", "33521", "733", "2243", "485", "486", "34553", "752", "721", "30656", "2016", "27507", "3180", "32127", "1982", "753", "994", "32175", "510", "732", "28695", "33581", "3178", "28687", "3946", "3177", "3173", "755", "3945", "734", "29997", "494", "28554", "1629", "3271", "27463", "32106", "472", "28543", "3265", "29998", "27266", "751", "2010"];

items = items.map{|i|
    {
      'id' => i,
      'template' => "#{i} = #{i} = #{i}"
    }
};

shop.user_shop_relations.select('id, uniqid, email').find_in_batches(batch_size: 100) do |batch|
  params = {
    'shop_id' => shop.uniqid.to_s,
    'shop_secret' => shop.secret.to_s,

    'send_from' => 'REES46 <noreply@rees46.com>',
    'subject' => 'Тестовая рассылка',
    'template' => 'Здрасьте, {{name}}! <br/> <b>Вот рекомендации:</b><hr/> {{recommendations}}. Можете отписываться: {{unsubscribe_url}}',

    'users' => batch.map{|u|
      {
        'id' => u.uniqid,
        'email' => u.email,
        'name' => u.uniqid
      }
    },

    'items' => items,

    'recommendations_limit' => '5'
  };

  mailer_job = MailerJob.create!(shop: shop, params: params)

  DigestMailerWorker.perform_async(mailer_job.id)
end
