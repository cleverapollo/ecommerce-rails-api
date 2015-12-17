namespace :yml do
  desc 'Process all YML'
  task :process_all => :environment do
    Shop.import_yml_files
  end
end
