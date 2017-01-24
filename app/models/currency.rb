class Currency < MasterTable
  after_find :protect_it
end
