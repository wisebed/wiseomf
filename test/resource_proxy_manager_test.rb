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
  @reservation



  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    EventBus.subscribe(Events::DOWN_ARE_NODES_ALIVE, self, :on_alive_request)
    info "Startup"
    Thread.new {
      OmfCommon.init(CONFIG[:env], communication: {url: CONFIG[:xmpp_url]}) {
        OmfCommon.comm.on_connected { |comm|
          info "WiseOMF >> Connected to XMPP server"
          # Test end???
          comm.on_interrupted {
            puts "WiseOMF >> Interrupt!"
            ResourceProxyManager.instance.handle_interrupt
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
    re.nodeUrns = ["urn:wisebed:uzl1:0x1", "urn:wisebed:uzl1:0x2"]
    re.secretReservationKeys = [ReservationEvent::SecretReservationKey.new(username: "user", nodeUrnPrefix: "urn:wisebed:uzl1:", key: "1"),
                                ReservationEvent::SecretReservationKey.new(username: "user", nodeUrnPrefix: "urn:wisebed:uzl2:", key: "2")]
    assert(re.valid?, "The ReservationEvent is invalid!")
    @reservation = re
    info "ReservationEvent created!"
    EventBus.publish(Events::RESERVATION_STARTED, event: re)
    info "ReservationEvent published!"
    while true
      sleep (10)
    end

  end

  def on_alive_request(payload)
    response = SingleNodeResponse.new
    response.reservationId = Utils::UIDHelper.reservation_uid(@reservation).gsub("-", "\n")
    response.nodeUrn = "urn:wisebed:uzl1:0x1"
    response.requestId = payload[:request].requestId
    response.statusCode = 1
    EventBus.publish(Events::IWSN_RESPONSE, event: response, requestId: response.requestId, nodeUrns: Set.new([response.nodeUrn]))
    OmfCommon.el.after(5) {
    response.nodeUrn= "urn:wisebed:uzl1:0x2"
    EventBus.publish(Events::IWSN_RESPONSE, event: response, requestId: response.requestId, nodeUrns: Set.new([response.nodeUrn]))
    }
  end

end