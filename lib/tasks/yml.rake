namespace :yml do

  desc 'Process all YML'
  task :process_all => :environment do
    YmlWorker.process_all
  end


  desc 'Process newbies'
  task :process_priority => :environment do
    YmlWorker.process_priority
  end


end
