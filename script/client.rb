require 'brb'
require 'benchmark'

core = BrB::Tunnel.create(nil, 'brb://localhost:5555')

threads = []
5.times do |i|
  threads[i] = Thread.new do
    10000.times do
      puts Benchmark.measure { puts core.recommend_block(155) }
    end
  end
end

threads.each {|t| t.join }
