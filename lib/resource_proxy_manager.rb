require_relative '../resources/event_type'
require 'singleton'
require 'omf_rc'
require 'base64'
require 'json'

class ResourceProxyManager
  include Singleton
  include De::Uniluebeck::Itm::Tr::Iwsn::Messages

  @resourceProxies


  def initialize
    @resourceProxies = {}
    EventBus.subscribe(Events::RESERVATION_STARTED, self, :on_reservation_started)
    EventBus.subscribe(Events::RESERVATION_ENDED, self, :on_reservation_ended)
    debug 'ResourceProxyManager started!'
  end

  def on_reservation_started(payload)
    info "on_reservation_started"
    reservation = payload[:event]
    debug JSON.generate(reservation.secretReservationKeys)
    if reservation.secretReservationKeys.count > 0
      key = Base64.encode64(JSON.generate(reservation.secretReservationKeys))
      opts = {uid: key, start_time: reservation.interval_start, end_time: reservation.interval_end, nodeUrns: reservation.nodeUrns, secretReservationKeys: reservation.secretReservationKeys}
      proxy = OmfRc::ResourceFactory.create(:wisebed_reservation,opts)
      @resourceProxies[key] = proxy
    else
      error 'There a no reservation keys in the list. Can\'t create new reservation proxy.'
    end
  end

  def on_reservation_ended(payload)
    reservation = payload[:event]
    key = Base64.encode64(JSON.generate(reservation.secretReservationKeys))
    proxy = @resourceProxies.delete(key)
    proxy.disconnect unless proxy.nil?
  end

  def handle_interrupt
    @resourceProxies.each { |k, v|
      v.disconnect
    }
  end

end