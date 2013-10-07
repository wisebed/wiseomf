require_relative '../protobuf/iwsn-messages.pb'
require_relative '../protobuf/internal-messages.pb'
require_relative '../protobuf/external-plugin-messages.pb'
require_relative '../utils/uid_helper'

require 'event_bus'
require 'omf_rc'
require 'set'

module OmfRc::ResourceProxy::WisebedReservation
  include OmfRc::ResourceProxyDSL
  include De::Uniluebeck::Itm::Tr::Iwsn::Messages

  attr_accessor :reservation_event, :child_hash

  @reservation_event
  @child_hash

  register_proxy :wisebed_reservation


  property :start_time, access: :init_only
  property :end_time,   access: :init_only
  property :nodeUrns,   access: :init_only

  hook :before_ready do |reservation|
    debug 'ReservationProxy: before_ready'
    reservation.reservation_event = reservation.opts.reservationEvent
    reservation.child_hash = {}
    # create the "all node group"
    nodeUrns = reservation.opts.nodeUrns
    child_uid = Utils::UIDHelper::node_group_uid(reservation.reservation_event, nodeUrns)
    proxy = reservation.create(:wisebed_node, {uid: child_uid, nodeUrns: nodeUrns})
    reservation.child_hash[child_uid] = proxy
    # create the "single node groups"
    nodeUrns.each {|nodeUrn|
      set = Set.new([nodeUrn])
      cuid = Utils::UIDHelper::node_group_uid(reservation.reservation_event, set)
      p = reservation.create(:wisebed_node, {uid: cuid, nodeUrns: set})
      reservation.child_hash[cuid] = p
    }
    debug "Reservation Proxy is ready with #{reservation.child_hash.count} node group proxies."
  end

  hook :before_release do |reservation|
    debug "#{reservation.uid} is now released"
  end


  # inherited methods
  def create(type, opts = {}, creation_opts = {}, &creation_callback)
    child_nodeUrns = opts[:nodeUrns]
    if child_nodeUrns.nil?
      error "No nodeUrns provided.."
      inform_creation_failed('Please provide a group of node urns to create a group topic for.')
      return nil
    end
    child_uid = Utils::UIDHelper.node_group_uid(self.reservation_event, child_nodeUrns)
    if self.child_hash.include? child_uid
      debug "The topic '#{child_uid}' already exists."
      inform('CREATION.FAILED'.to_sym, {reason: ' There exists an appropriate group topic for the provided set of nodeUrns.', uid: child_uid})
      return self.child_hash[child_uid]
    end
    super(type, opts, creation_opts, &creation_callback)
  end

end


