require 'bundler/setup'
require 'webmetrics'
require 'rack/test'

RSpec.configure do |config|

  config.before(:suite) do
    # setup the Webmetrics test database
    Webmetrics.configure do |c|
      puts "configured to use webmetrics_metrics_test db"
      c.database_name = "webmetrics_metrics_test"
    end
  end

  config.before(:each) do
    Webmetrics.database.collections.select {|c| c.name !~ /system/ }.each(&:drop)
  end

  config.include(Rack::Test::Methods)

  # add helper methods here

end