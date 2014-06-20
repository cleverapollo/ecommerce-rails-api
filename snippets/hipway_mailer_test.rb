Redis.new.flushall

MailerJob.delete_all

reload!

shop = Shop.find(134)

items = shop.items.available.map{|i|
    {
      'id' => i.uniqid.to_s,
      'template' => "#{i.uniqid} = #{i.name} = #{i.url}"
    }
};

shop.user_shop_relations.where('user_id > 2563512').select('id, uniqid').find_in_batches(batch_size: 100) do |batch|
  params = {
    'shop_id' => shop.uniqid.to_s,
    'shop_secret' => shop.secret.to_s,

    'send_from' => 'REES46 <noreply@rees46.com>',
    'subject' => 'Тестовая рассылка',
    'template' => 'Здрасьте, {{name}}! <br/> <b>Вот рекомендации:</b><hr/> {{recommendations}}. Можете отписываться: {{unsubscribe_url}}',

    'users' => batch.map{|u|
      {
        'id' => u.uniqid,
        'email' => 'test@test.test',
        'name' => u.uniqid,
        'unsubscribe_url' => 'lol no'
      }
    },

    'items' => items,

    'recommendations_limit' => '5'
  };

  mailer_job = MailerJob.create!(shop: shop, params: params)

  DigestMailerWorker.perform_async(mailer_job.id)
end
