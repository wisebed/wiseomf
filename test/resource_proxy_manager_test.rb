require 'yaml'
CONFIG = YAML.load_file '../config.yml'

# requiring WiseOMF classes and helpers:
# Need omf_rc gem to be required, this will load all dependencies

require 'omf_rc'
require 'protocol_buffers'


require 'test/unit'
require 'event_bus'
require_relative '../protobuf/internal-messages.pb'
require_relative '../protobuf/external-plugin-messages.pb'
require_relative '../protobuf/iwsn-messages.pb'
require_relative '../resources/event_type'
require_relative '../lib/resource_proxy_manager'

class ResourceProxyManagerTest < Test::Unit::TestCase
  include De::Uniluebeck::Itm::Tr::Iwsn::Messages




  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    info "Startup"
    Thread.new {
      OmfCommon.init(CONFIG[:env], communication: {url: CONFIG[:xmpp_url]}) {
        OmfCommon.comm.on_connected { |comm|
          info "WiseOMF >> Connected to XMPP server"
          # Test end???
          comm.on_interrupted {
            puts "WiseOMF >> Interrupt!"
            ResourceProxyManager.instance.handleInterrupt
          }
        }
      }
    }.run
    sleep(5)

    OmfRc::ResourceFactory.load_additional_resource_proxies('../lib')
    ResourceProxyManager.instance
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end


  def test_reservation_start
    re = ReservationEvent.new
    re.interval_start = DateTime.now.to_s
    re.interval_end = (DateTime.now + 1.hour).to_s
    re.type = ReservationEvent::Type::STARTED
    re.nodeUrns = ["urn:wisebed:uzl1:0x112", "urn:wisebed:uzl1:0x33", "urn:wisebed:uzl1:0x033"]
    re.secretReservationKeys = [ReservationEvent::SecretReservationKey.new(username: "user", nodeUrnPrefix: "urn:wisebed:uzl1", key: "1"),
                                ReservationEvent::SecretReservationKey.new(username: "user", nodeUrnPrefix: "urn:wisebed:uzl2", key: "2")]
    assert(re.valid?, "The ReservationEvent is invalid!")
    info "ReservationEvent created!"
    EventBus.publish(Events::RESERVATION_STARTED, event: re)
    info "ReservationEvent published!"

    while true
      sleep (10)
    end

    #sleep(5)
    #re2 = ReservationEvent.new
    #re2.interval_start = DateTime.now.to_s
    #re2.interval_end = (DateTime.now + 1.hour).to_s
    #re2.type = ReservationEvent::Type::ENDED
    #re2.nodeUrns = ["urn:wisebed:uzl1:0x112", "urn:wisebed:uzl1:0x33", "urn:wisebed:uzl1:0x033"]
    #re2.secretReservationKeys = [ReservationEvent::SecretReservationKey.new(username: "user", nodeUrnPrefix: "urn:wisebed:uzl1", key: "1"),
    #                            ReservationEvent::SecretReservationKey.new(username: "user", nodeUrnPrefix: "urn:wisebed:uzl2", key: "2")]
    #assert(re.valid?, "The ReservationEvent is invalid!")
    #EventBus.publish(Events::RESERVATION_ENDED, event: re2)
    #sleep(5)
  end

end