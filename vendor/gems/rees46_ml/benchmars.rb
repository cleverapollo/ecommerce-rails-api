lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "rees46_ml"
require "benchmark"
require "open-uri"
require "pry"

xml = open("/Users/andi/dev/ruby/mk/rees/api/vendor/gems/rees46_ml/example.yml")

a = Rees46ML::File.new(xml)

Benchmark.bmbm do |x|
  x.report { a.take(100).to_a }
end

# OX
#
# Rehearsal ------------------------------------
#    1.210000   0.000000   1.210000 (  1.213684)
# --------------------------- total: 1.210000sec

#        user     system      total        real
#    1.170000   0.010000   1.180000 (  1.171431)

# Nokogiri
#
# Rehearsal ------------------------------------
#    1.070000   0.000000   1.070000 (  1.067990)
# --------------------------- total: 1.070000sec

#        user     system      total        real
#    1.100000   0.000000   1.100000 (  1.101216)