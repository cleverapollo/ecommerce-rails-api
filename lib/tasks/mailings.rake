namespace :mailings do

  desc 'Process trigger mailings'
  task :trigger_process_all => :environment do
    TriggerMailings::ClientsProcessor.process_all
  end


  desc 'Process bounced letters'
  task :handle_bounces => :environment do
    BounceHandlerWorker.perform
  end


end
