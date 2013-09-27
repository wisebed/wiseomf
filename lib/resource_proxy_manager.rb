require_relative '../resources/event_type'
require 'singleton'
require 'omf_rc'
require 'base64'
require 'json'

class ResourceProxyManager
  include Singleton
  include De::Uniluebeck::Itm::Tr::Iwsn::Messages


  @resourceProxies = {}

    #OmfCommon.init(CONFIG[:env], communication: {url: CONFIG[:xmpp_url]}) do
    #  OmfCommon.comm.on_connected do |comm|
    #    info "ResourceProxyManager >> Connected to XMPP server"
    #    # Test end???
    #    comm.on_interrupted {
    #      puts "ResourceProxyManager >> Interrupt!"
    #      @resourceProxies.each { |k, r| r.disconnect } unless @resourceProxies.nil?
    #    }
    #  end
    #end

  def initialize
      EventBus.subscribe(Events::RESERVATION_STARTED, self, :on_reservation_started)
      EventBus.subscribe(Events::RESERVATION_ENDED, self, :on_reservation_ended)
      debug 'ResourceProxyManager started!'
  end

  def on_reservation_started(payload)
    info "Reservation started: #{payload[:event]}"
    reservation = payload[:event]
    key = Base64.encode64(JSON.generate(reservation.secretReservationKeys))

    # TODO provide options to the create method
    proxy = OmfRc::ResourceFactory.create(:wisebed_reservation, uid: key)
    @resourceProxies[key] = proxy
  end

  def on_reservation_ended(payload)
    reservation = payload[:event]
    proxy = @resourceProxies.delete(reservation.key)
    proxy.disconnect unless proxy.nil?
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