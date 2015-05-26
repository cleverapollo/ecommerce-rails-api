namespace :populate do

  desc 'Clear data after populate'
  task :clear do
    ap "Clearing"
    Experimentor::Experiments::Base.new.clear_all
  end

  desc 'Experiment task'
  task :experiment do
    ap 'Start experiment'
    params = OpenStruct.new(shop: Shop.find_by(name:'Megashop'), user: User.find(1), limit: 7, type:'experiment')
    experiment = Experimentor::Experiments::ItemBasedExperiment.new
    experiment.iterate(params)
  end

  desc 'Populate data for experiment task'
  task :data do
    ap 'Populate experiment'
    experiment = Experimentor::Experiments::ItemBasedExperiment.new
    experiment.populate
  end

end

