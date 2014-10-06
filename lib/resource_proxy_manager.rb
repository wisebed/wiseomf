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
    EventBus.subscribe(Events::RESERVATION_CANCELLED, self, :on_reservation_cancelled)
    debug 'ResourceProxyManager started!'
  end

  def on_reservation_started(payload)
    debug 'on_reservation_started'
    reservation = payload[:event]
    if reservation.secretReservationKeys.count > 0
      key = WiseOMFUtils::UIDHelper.reservation_uid(reservation)
      unless @resourceProxies[key].nil?
        info "Reservation proxy with key \"#{key}\" already exists."
      else
        info "Starting reservation with key \"#{key}\"."
        opts = {uid: key, start_time: reservation.interval_start, end_time: reservation.interval_end, nodeUrns: reservation.nodeUrns, reservationEvent: reservation}
        proxy = OmfRc::ResourceFactory.create(:wisebed_reservation, opts)
        @resourceProxies[key] = proxy
      end
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

  def on_reservation_cancelled(payload)
    debug 'on_reservation_cancelled'
    reservation = payload[:event]
    key = WiseOMFUtils::UIDHelper.reservation_uid(reservation)

    proxy = @resourceProxies[key]

    unless proxy.nil? || reservation.cancelled.nil?
      cancelled_time = Time.at(reservation.cancelled.to_f)

      if cancelled_time <= Time.now
        info "Reservation was cancelled at #{cancelled_time.to_s}."
        @resourceProxies.delete(key)
        proxy.release_self
      end
    end
  end

  def handle_interrupt
    warn 'Interrupt!'
  end

end