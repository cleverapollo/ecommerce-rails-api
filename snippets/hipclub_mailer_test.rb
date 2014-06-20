def hipclub_mailer
  Redis.new.flushall
  Mailing.delete_all; MailingBatch.delete_all
  reload!

  shop_id     = 'c441abf5dc8c9f3a46f12af52f3148';
  shop_secret = 'c7b8f06243e90286caa18ba0ac948e5b';
  url         = 'http://localhost:8080/';
  send_from   = 'HIPCLUB <messages@hipclub.ru>'
  subject     = "Июньские праздники с hipclub: на Скиатос за 5000 рублей, Сардиния от 433€, The Queen of Montenegro 4* в Черногории от 842€, Thalasso & Terroir во Франции, Норвежские фьорды за 43750 рублей, Holiday Inn Lesnaya 4* -46%, Кипр, Родос и многое другое"

  body = {
    'shop_id'     => shop_id,
    'shop_secret' => shop_secret,
    'send_from'   => send_from,
    'subject'     => subject,
    'template'    => File.read('/Users/anton-zh/git/rees46_api/snippets/hipclub_template.html'),
    'items'       => ["travel6851", "travel6855", "travel6862", "travel6829", "travel6867", "travel6869", "travel6870", "travel6874", "travel6877", "travel6881", "travel6884", "travel6885", "travel6853", "travel6858", "travel6883", "travel6875", "travel6864", "travel6846", "travel6842", "travel6879", "travel6878", "travel6844", "travel6871", "travel6866", "travel6854", "travel6841", "travel6876", "travel6872", "travel6882", "travel6865", "travel6860", "travel6857", "travel6863", "travel6880", "travel6868", "travel6859", "travel6856", "travel6861", "travel6658", "travel6779", "travel6830", "travel6831", "travel6832"]
  };

  resp = HTTParty.post(url + 'mailings',
      body: body.to_json,
      headers: { 'Content-Type' => 'application/json' }
  );

  batch = []

  File.open('snippets/hipclub_users_filtered.csv').each do |line|
    id, email, token = line.gsub("\n", '').split('|');

    batch << {
      'id' => id.to_s,
      'email' => email,
      'token' => token.to_s
    };

    if batch.count > 100
      body = {
        'shop_id' => shop_id,
        'shop_secret' => shop_secret,
        'users' => batch
      };

      HTTParty.post("#{url}mailings/#{resp}/perform", body: body.to_json, headers: { 'Content-Type' => 'application/json' });

      batch = []
      raise 'lol'
    end
  end
end