
  shop_id     = 'c441abf5dc8c9f3a46f12af52f3148';
  shop_secret = 'c7b8f06243e90286caa18ba0ac948e5b';
  url         = 'http://api.rees46.com/';
  send_from   = 'HIPCLUB <messages@hipclub.ru>'
  subject     = "Самое интересное за неделю в hipclub"

  body = {
    'shop_id'     => shop_id,
    'shop_secret' => shop_secret,
    'send_from'   => send_from,
    'subject'     => subject,
    'template'    => File.read('/home/rails/hipclub_template_3.html'),
    'items'       => ["travel6950", "travel6972", "travel6961", "travel6971", "travel6942", "travel6952", "travel6970", "travel6962", "travel6973", "travel6963", "travel6974", "travel6967", "travel6968", "travel6964", "travel6965", "travel6960", "travel6959", "travel6943", "travel6969", "travel6947", "travel6946", "travel6958", "travel6966", "travel6944", "travel6948", "travel6957", "travel6945", "travel6937", "travel6935", "travel6933", "travel6951", "travel6917", "travel6934", "travel6949", "travel6955", "travel6931", "travel6956", "travel6954"]
  };

  resp = HTTParty.post(url + 'mailings',
      body: body.to_json,
      headers: { 'Content-Type' => 'application/json' }
  );

  batch = []

  File.open('/home/rails/hipclub_users_filtered_20140711.csv').each do |line|
    id, email, token = line.gsub("\n", '').split(',');

    batch << {
      'id' => id.to_s,
      #'email' => email,
      'email' => 'anton.zhavoronkov@mkechinov.ru',
      'token' => token.to_s
    };

    if batch.count > 2
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