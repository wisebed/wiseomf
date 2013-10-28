require_relative '../resources/event_type'
require 'singleton'
require 'omf_rc'
require 'base64'
require 'json'
require 'wise_omf/server'

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
    debug 'on_reservation_started'
    reservation = payload[:event]
    if reservation.secretReservationKeys.count > 0
      key = WiseOMFUtils::UIDHelper.reservation_uid(reservation)
      info "Starting reservation with key \"#{key}\"."
      opts = {uid: key, start_time: reservation.interval_start, end_time: reservation.interval_end, nodeUrns: reservation.nodeUrns, reservationEvent: reservation}
      proxy = OmfRc::ResourceFactory.create(:wisebed_reservation,opts)
      @resourceProxies[key] = proxy
    else
      error 'There are no reservation keys in the list. Can\'t create new reservation proxy.'
    end
    debug 'end on_reservation_started'
  end

  def on_reservation_ended(payload)
    debug 'on_reservation_ended'
    reservation = payload[:event]
    key = WiseOMFUtils::UIDHelper.reservation_uid(reservation)
    proxy = @resourceProxies.delete(key)
    proxy.release_self unless proxy.nil?
  end

  def handle_interrupt
    warn 'Interrupt!'
  end

end