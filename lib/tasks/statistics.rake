namespace :statistics do

  desc 'Sales Rate Calculator'
  task :sales_rate => :environment do
    SalesRateCalculator.perform
  end


  desc 'Sales Rate Calculator for newbies'
  task :sales_rate_newbies => :environment do
    SalesRateCalculator.perform_newbies
  end

  desc 'Calculate promotion results for previous day'
  task :calculate_yesterday_promotion => :environment do
    Promoting::Calculator.previous_days
  end

end
