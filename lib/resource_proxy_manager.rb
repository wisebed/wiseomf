require_relative '../resources/event_type'
require 'singleton'

class ResourceProxyManager
  include Singleton
  include De::Uniluebeck::Itm::Tr::Iwsn::Messages

  @resourceProxies = []

  def initialize
      OmfCommon.init(CONFIG[:env], communication: { url: CONFIG[:xmpp_url] }) do
        OmfCommon.comm.on_connected do |comm|

          # TODO: I think this is just a quick test?
          info "ResourceProxyManager >> Connected to XMPP server"
          # Test end???
          comm.on_interrupted {
            puts "ResourceProxyManager >> Interrupt!"
            rpm.each {|r| r.disconnect}
          }
        end
      end

    end
    EventBus.subscribe(Events::RESERVATION_STARTED, self, :on_reservation_started)
    EventBus.subscribe(Events::RESERVATION_ENDED, self, :on_reservation_ended)
  end

  def on_reservation_started(payload)
    info "Reservation started: #{payload[:event]}"
    reservation = payload[:event]
    # TODO provide options to the create method
    OmfRc::ResourceFactory.create(:wisebed_reservation, {})
  end

  def on_reservation_ended(payload)

  end
end



## This init method will set up your run time environment,
## communication, eventloop, logging etc. We will explain that later.
## Need to be called only once ??
#OmfCommon.init(CONFIG[:env], communication: { url: CONFIG[:xmpp_url] }) do
#  OmfCommon.comm.on_connected do |comm|
#
#    # TODO: I think this is just a quick test?
#    info "ResourceProxyManager >> Connected to XMPP server"
#    rpm = []
#    rpm << OmfRc::ResourceFactory.create(:wisebed_reservation, uid: 'wisebed')
#    # Test end???
#    comm.on_interrupted {
#      puts "ResourceProxyManager >> Interrupt!"
#      ReservationWatcher.instance.terminate
#      rpm.each {|r| r.disconnect}
#    }
#  end
#
#  # Starting the reservation watcher as part of WiseResourceManager
#  ReservationWatcher.instance.start
#end