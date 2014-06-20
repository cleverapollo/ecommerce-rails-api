def dom98mail
  Redis.new.flushall
  Mailing.delete_all; MailingBatch.delete_all
  reload!

  shop = Shop.find(1)

  url = 'http://127.0.0.1:8080/'
  body = {
    'shop_id'     => shop.uniqid,
    'shop_secret' => shop.secret,
    'send_from'   => 'REES46 <noreply@rees46.com>',
    'subject'     => 'Вы приглашены на закрытую распродажу в DOM98',
    'template'    => File.read('/Users/anton-zh/git/rees46_api/snippets/dom98.html'),
    'business_rules' => [{ 'id' => '40865'}]
  };

  resp = HTTParty.post(url + 'mailings',
    body: body.to_json,
    headers: { 'Content-Type' => 'application/json' }
  );

  shop.user_shop_relations.with_email.select('id, uniqid, email').find_in_batches(batch_size: 100) do |batch|
    body = {
      'shop_id' => shop.uniqid,
      'shop_secret' => shop.secret,
      'users' => batch.map{|u|
        {
          'id' => u.uniqid,
          'email' => u.email,
          'name' => u.uniqid,
          'unsubscribe_url' => 'http://dom98.ru'
        }
      }
    };

    HTTParty.post("#{url}mailings/#{resp}/perform",
      body: body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    );
  end
end