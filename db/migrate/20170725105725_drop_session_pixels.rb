class DropSessionPixels < ActiveRecord::Migration
  def change
    execute 'alter table sessions drop column synced_with_republer_at cascade';
    execute 'alter table sessions drop column synced_with_advmaker_at cascade';
    execute 'alter table sessions drop column synced_with_doubleclick_at cascade';
    execute 'alter table sessions drop column synced_with_doubleclick_cart_at cascade';
    execute 'alter table sessions drop column synced_with_facebook_at cascade';
    execute 'alter table sessions drop column synced_with_facebook_cart_at cascade';
  end
end
