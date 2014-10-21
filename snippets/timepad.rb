first_line = true; orders = [];
File.open('/Users/anton-zh/Downloads/query_result.csv').each_line do |line|
  if first_line
    first_line = false; next;
  end

  user_id, user_email, event_id, timestamp, _ = line.gsub("\n", '').split(';').map{|e| e.gsub('"', '')}

  puts "#{user_id} -> #{event_id}"
end