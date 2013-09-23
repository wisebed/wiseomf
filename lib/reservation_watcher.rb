require 'singleton'
require 'rest-client'
require 'json'


# The reservation watcher is designed as singleton. The watcher starts in its ownn thread and polls reservations from the rest api every POLL_INTERVAL seconds.
class ReservationWatcher
  include Singleton
  DEFAULT_HEADERS = {:content_type => "application/json", :accept => "application/json"}

  # default poll interval in seconds
  POLL_INTERVAL = 10

  @terminationFlag = false

  # starting the poll thread
  def start
    if !@pollThread
      @pollThread = Thread.new {
        puts 'Starting ReservationWatcher run loop'
        while !@terminationFlag do
          self.poll_reservations
          sleep(POLL_INTERVAL)
        end
        puts 'Terminating ReservationWatcher run loop'
      }
    end
  end

  # This method safely terminates the reservation watcher after the current iteration of the run loop was completed.
  def terminate
    @terminationFlag = true
  end

  def kill
    puts 'ReservationWatcher >> Killing the poll thread'
    @pollThread.kill
  end

  def poll_reservations
    #TODO do something with the response.

    resource = RestClient::Resource.new "#{CONFIG[:wisebed_rest_api]}/reservations", :headers => DEFAULT_HEADERS
    begin
      json = resource.get(:content_type => "text/json")
      result = JSON.parse(json)
      puts(result["reservations"].to_yaml)
      reservations = result["reservations"]

      reservations.each do |r|
        puts 'Next Reservation:'
        puts "\tFrom #{Time.at (r["from"])}"
        puts "\tTo #{Time.at (r["to"])}"
        puts "\tNodes: \t#{r["nodeURNs"]}"

      end
    rescue => e
      puts "Error while fetching information from resource #{resource}:"
      puts e.message
    end
  end

  def poll_nodes
    #TODO do something with the response.
    puts("Testing simple rest client ...")
    resource = RestClient::Resource.new "#{CONFIG[:wisebed_rest_api]}/experiments/network", :headers => DEFAULT_HEADERS

    begin
      json = resource.get
      puts JSON.parse(json).to_yaml
    rescue => e
      puts e.message
    end
  end


end