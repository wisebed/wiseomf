require_relative '../resources/event_type'
require_relative '../utils/uid_helper'
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
    if reservation.secretReservationKeys.count > 0
      key = Utils::UIDHelper.reservation_uid(reservation)
      opts = {uid: key, start_time: reservation.interval_start, end_time: reservation.interval_end, nodeUrns: reservation.nodeUrns, reservationEvent: reservation}
      proxy = OmfRc::ResourceFactory.create(:wisebed_reservation,opts)
      proxy
      @resourceProxies[key] = proxy
    else
      error 'There are no reservation keys in the list. Can\'t create new reservation proxy.'
    end
  end

  def on_reservation_ended(payload)
    reservation = payload[:event]
    key = Utils::UIDHelper.reservation_uid(reservation)
    proxy = @resourceProxies.delete(key)
    proxy.release_self unless proxy.nil?
  end

  def handle_interrupt
    @resourceProxies.each { |k, v|
      v.release_self
    }
  end

end