def dom98mail
  Redis.new.flushall
  Mailing.delete_all; MailingBatch.delete_all
  reload!

  shop = Shop.find(1)

  url = 'http://api.rees46.com/'
  body = {
    'shop_id'     => shop.uniqid,
    'shop_secret' => shop.secret,
    'send_from'   => 'DOM98.RU <web@dom98.ru>',
    'subject'     => 'Вы приглашены на закрытую распродажу в DOM98',
    'template'    => File.read('/Users/anton-zh/git/rees46_api/snippets/dom98.html'),
    'business_rules' => [{ 'id' => '40865'}]
  };

  resp = HTTParty.post(url + 'mailings',
    body: body.to_json,
    headers: { 'Content-Type' => 'application/json' }
  );

  shop.user_shop_relations.with_email.select('id, uniqid, email').find_in_batches(batch_size: 3) do |batch|
    body = {
      'shop_id' => shop.uniqid,
      'shop_secret' => shop.secret,
      'users' => batch.map{|u|
        {
          'id' => u.uniqid,
          #'email' => 'kechinoff@gmail.com',
          #'email' => 'mobiling@mail.ru',
          'email' => 'anton.zhavoronkov@mkechinov.ru',
          'name' => 'Константин Константинопольский',
          'unsubscribe_url' => "http://dom98.ru/users/#{u.uniqid}/dashboard"
        }
      }
    };

    HTTParty.post("#{url}mailings/#{resp}/perform",
      body: body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    );
    break
  end
end