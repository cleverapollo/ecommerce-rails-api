shop_id     = 'f95342356fa619749015b7225f3b7db3';
shop_secret = '08d43a570bdeab3c8f5b5e1e5b357491';
url         = 'http://api.rees46.com/';

body = {
  'shop_id'     => shop_id,
  'shop_secret' => shop_secret,
  'send_from'   => 'DOM98.RU <web@dom98.ru>',
  'subject'     => 'Удачная покупка ждет Вас в ДОМ98',
  'template'    => File.read('/Users/anton-zh/git/rees46_api/snippets/dom98.html'),
  'business_rules' => []#[{ 'id' => '40865'}]
};

resp = HTTParty.post(url + 'mailings',
    body: body.to_json,
    headers: { 'Content-Type' => 'application/json' }
);

def filtered_email(email)
  if email.present?
    if email  =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      unless email.include?('@dom98')
        return email.downcase.strip
      end
    end
  end
end

User.where(subscribed: true).find_in_batches(batch_size: 2) do |batch|
  users = []

  batch.each do |user|
    email = filtered_email(user.email)
    next if email.nil?
    user_object = {
      'id' => user.id.to_s,
      #'email' => email,
      'email' => 'anton.zhavoronkov@mkechinov.ru',
      'name' => user.name,
      'unsubscribe_url' => "http://dom98.ru/users/#{user.id}/dashboard"
    }
    users << user_object
  end

  next if users.none?

  body = {
    'shop_id' => shop_id,
    'shop_secret' => shop_secret,
    'users' => users
  }

  HTTParty.post("#{url}mailings/#{resp}/perform",
    body: body.to_json,
    headers: { 'Content-Type' => 'application/json' }
  )
  break
end
