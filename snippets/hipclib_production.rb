def hipclub_mailer
  Redis.new.flushall
  Mailing.delete_all; MailingBatch.delete_all
  reload!

  shop_id     = 'c441abf5dc8c9f3a46f12af52f3148';
  shop_secret = 'c7b8f06243e90286caa18ba0ac948e5b';
  url         = 'http://api.rees46.com/';
  send_from   = 'HIPCLUB <messages@hipclub.ru>'
  subject     = "Супер выгодные предложение на Санторини от 120€, рай на островах Пхи-Пхи от 1106$, Ararat Park Hyatt 5* до 53%, Солнечная Болгария от 492€, остров Искья от 890€, Норвежские фьорды от 400€, Новогодние праздники в Уганде от 3000$, Черногория от 625€, Камбоджа, Гоа, Крит и многое другое на hipclub"

  body = {
    'shop_id'     => shop_id,
    'shop_secret' => shop_secret,
    'send_from'   => send_from,
    'subject'     => subject,
    'template'    => File.read('snippets/hipclub_template_2.html'),
    'items'       => ["travel6851", "travel6855", "travel6862", "travel6867", "travel6869", "travel6870", "travel6874", "travel6877", "travel6884", "travel6853", "travel6858", "travel6883", "travel6875", "travel6864", "travel6842", "travel6879", "travel6878", "travel6844", "travel6871", "travel6854", "travel6876", "travel6860", "travel6861", "travel6880", "travel6868", "travel6859", "travel6885", "travel6863", "travel6872", "travel6886", "travel6887", "travel6889", "travel6888", "travel6891", "travel6890", "travel6892", "travel6893", "travel6895", "travel6897", "travel6898", "travel6899", "travel6900", "travel6902", "travel6903", "travel6904", "travel6865", "travel6856", "travel6882", "travel6866", "travel6658", "travel6881", "travel6857", "travel6830", "travel6831"]
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
      'email' => 'anton.zhavoronkov@mkechinov.ru',
      'token' => token.to_s
    };

    if batch.count > 0
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