namespace :statistics do

  desc 'Sales Rate Calculator'
  task :sales_rate => :environment do
    SalesRateCalculator.perform
  end


  desc 'Sales Rate Calculator for newbies'
  task :sales_rate_newbies => :environment do
    SalesRateCalculator.perform_newbies
  end


end
