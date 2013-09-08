# encoding: utf-8

require "mongo"
require "webmetrics/config"
require "webmetrics/session"

require "rack"
require "webmetrics/middleware"

# add railtie
if defined?(Rails)
  require "webmetrics/railtie"
end

# helper method to initialize an Webmetrics session
def Webmetrics(env_or_model, attributes = nil)
  if env_or_model.is_a?(Hash) and env_or_model["webmetrics.session"]
    env_or_model["webmetrics.session"]
  else
    session = Webmetrics::Session.new(env_or_model, attributes)

    # add to the rack env (if applicable)
    env_or_model["webmetrics.session"] = session if env_or_model.is_a?(Hash)

    session
  end

end

module Webmetrics

  class << self

    # Sets the Mongoid configuration options. Best used by passing a block.
    #
    # @example Set up configuration options.
    #
    #   Webmetrics.configure do |config|
    #     config.database = Mongo::Connection.new.db("metrics")
    #   end
    #
    # @return [ Config ] The configuration obejct.
    def configure
      config = Webmetrics::Config
      block_given? ? yield(config) : config
    end
    alias :config :configure
  end

  # Take all the public instance methods from the Config singleton and allow
  # them to be accessed through the Webmetrics module directly.
  #
  # @example Delegate the configuration methods.
  #   Webmetrics.database = Mongo::Connection.new.db("test")
  Webmetrics::Config.public_instance_methods(false).each do |name|
    (class << self; self; end).class_eval <<-EOT
      def #{name}(*args)
        configure.send("#{name}", *args)
      end
    EOT
  end

end