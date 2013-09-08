# encoding: utf-8

require "active_support/core_ext/hash/indifferent_access"

module Webmetrics

  # an AARR session is used to identify a particular user in order to track events
  class Session
    attr_accessor :id
    attr_accessor :env

    # find or creates a session in the db based on the env or object
    def initialize(env_or_object = nil, attributes = nil)
      # if it's an object with an id, then return that
      if env_or_object.respond_to?(:id) and env_or_object.id.is_a?(BSON::ObjectId)
        user_id = env_or_object.id.to_s
        attributes = {"$set" => attributes || {}}
        Webmetrics.users.update({"user_id" => user_id}, attributes, :upsert => true, :safe => true)

        # set newly created id
        user = Webmetrics.users.find_one({"user_id" => user_id})
        self.id = user["_id"] if user.present?
      else
        # perform upsert to build object
        self.env = env_or_object
        self.id = parse_id(env_or_object) || BSON::ObjectId.new.to_s

        attributes = {"$set" => build_attributes(env_or_object).merge(attributes || {})}
        Webmetrics.users.update({"_id" => id}, attributes, :upsert => true)
      end

    rescue Exception => e
      if Webmetrics.suppress_errors
        puts "Unable to log metrics: #{e.to_s}"
      else
        raise e
      end
    end

    # returns a reference the othe Webmetrics user
    def user
      Webmetrics.users.find_one('_id' => id)
    end

    # sets some additional data
    def set_data(data)
      update({"data" => {"$set" => data}})
    end

    # save a cookie to the response
    def set_cookie(response)
      response.set_cookie(Webmetrics::Config.cookie_name, {
        :value => self.id,
        :path => "/",
        :expires => Time.now+Webmetrics::Config.cookie_expiration
      })
    end

    # track event name
    def track(event_name, options = {})
      options = options.with_indifferent_access

      # add event tracking
      result = Webmetrics.events.insert({
        "webmetrics_user_id" => self.id,
        "event_name" => event_name.to_s,
        "event_type" => translate_event_type(options["event_type"]),
        "complete" => options["complete"] || false,
        "data" => options["data"],
        "revenue" => options["revenue"],
        "referral_code" => options["referral_code"],
        "client" => options["client"] || get_client_name,
        "user_agent" => options["user_agent"] || get_user_agent,
        "created_at" => options["created_at"] || Time.now.getutc
      })

      # update user with last updated time
      user_updates = {
        "last_event_at" => Time.now.getutc
      }
      user_updates["user_id"] = options["user_id"].to_s if options["user_id"]
      update({
        "$set" => user_updates
      })

      result

    rescue Exception => e
      if Webmetrics.suppress_errors
        puts "Unable to log metrics: #{e.to_s}"
      else
        raise e
      end
    end

    def track!(event_name, options = {})
      options[:complete] = true
      track(event_name, options)
    end

    # helpers

    def acquisition(event_name, options = {})
      options[:event_type] = :acquisition
      track(event_name, options)
    end
    alias :acq :acquisition

    def acquisition!(event_name, options = {})
      options[:complete] = true
      acquisition(event_name, options)
    end
    alias :acq! :acquisition!

    def activation(event_name, options = {})
      options[:event_type] = :activation
      track(event_name, options)
    end
    alias :act :activation

    def activation!(event_name, options = {})
      options[:complete] = true
      activation(event_name, options)
    end
    alias :act! :activation!

    def retention(event_name, options = {})
      options[:event_type] = :retention
      track(event_name, options)
    end
    alias :ret :retention

    def retention!(event_name, options = {})
      options[:complete] = true
      retention(event_name, options)
    end
    alias :ret! :retention!

    def referral(event_name, options = {})
      options[:event_type] = :referral
      track(event_name, options)
    end
    alias :ref :referral

    def referral!(event_name, options = {})
      options[:complete] = true
      referral(event_name, options)
    end
    alias :ref! :referral!

    def revenue(event_name, options = {})
      options[:event_type] = :revenue
      track(event_name, options)
    end
    alias :rev :revenue

    def revenue!(event_name, options = {})
      options[:complete] = true
      revenue(event_name, options)
    end
    alias :rev! :revenue!

    protected

    # expand event type
    def translate_event_type(event_type)
      event_type = event_type.to_s
      case event_type
      when "acq"
        "acquisition"
      when "act"
        "activation"
      when "ret"
        "retention"
      when "rev"
        "revenue"
      when "ref"
        "referral"
      else
        event_type
      end
    end

    # mark update
    def update(attributes, options = {})
      Webmetrics.users.update({"_id" => id}, attributes, options)
    end

    # returns id
    def parse_id(env_or_object)
      # check for empty case or string

      # if it's a hash, then process like a request and pull out the cookie
      if env_or_object.is_a?(Hash)
        if env_or_object["rack.session"].is_a?(Hash) and env_or_object["rack.session"]["user_id"]
          # lookup user_id
          user = Webmetrics.users.find_one({"user_id" => env_or_object["rack.session"]["user_id"].to_s})
          if user.present?
            if env_or_object["webmetrics.id"]
              # TODO: convert webmetrics.id items to attach to current user
            end

            user["_id"]
          end
        elsif env_or_object["webmetrics.id"]
          env_or_object["webmetrics.id"]
        else
          request = Rack::Request.new(env_or_object)
          request.cookies[Webmetrics::Config.cookie_name]
        end
      # if it's a string
      elsif env_or_object.is_a?(String)
        env_or_object
      end
    end

    # try to pull out client name from env
    def get_client_name
      client_name = nil
      if env.present?
        Webmetrics::Config.client_matchers.each do |key, matcher|
          if matcher.respond_to?(:call) and matcher.call(env)
            client_name = key
            break
          end
        end
      end

      # return client name
      client_name || Webmetrics::Config.default_client
    end

    def get_user_agent
      if env.present?
        env["HTTP_USER_AGENT"].to_s
      end
    end

    # returns updates
    def build_attributes(env_or_object)
      if env_or_object.is_a?(Hash)
        user_attributes = {}

        # referrer: HTTP_REFERER
        referrer = env_or_object["HTTP_REFERER"]
        user_attributes["referrer"] = referrer if referrer

        # ip_address: HTTP_X_REAL_IP || REMOTE_ADDR
        ip_address = env_or_object["HTTP_X_REAL_IP"] || env_or_object["REMOTE_ADDR"]
        user_attributes["ip_address"] = ip_address if ip_address

        # set user_id if its in the session
        if env_or_object["rack.session"].is_a?(Hash) and env_or_object["rack.session"]["user_id"]
          user_attributes["user_id"] = env_or_object["rack.session"]["user_id"].to_s
        end

        user_attributes
      else
        {}
      end
    end

  end
end