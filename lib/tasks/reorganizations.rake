namespace :reorganizations do
  desc "Reorganizes categories in Action and Item"
  task categories: :environment do
    Item.find_in_batches do |batch|
      Item.connection.execute("
        UPDATE items 
        SET categories = ARRAY[category_uniqid] 
        WHERE category_uniqid is not null AND category_uniqid != ''
        AND id IN (#{batch.map(&:id).join(',')})
      ")
    end

    Action.find_in_batches do |batch|
      Action.connection.execute("
        UPDATE actions 
        SET categories = ARRAY[category_uniqid] 
        WHERE category_uniqid is not null AND category_uniqid != ''
        AND id IN (#{batch.map(&:id).join(',')})
      ")
    end
  end

end
