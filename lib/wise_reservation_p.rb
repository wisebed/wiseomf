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

  attr_accessor :reservation_event

  @reservation_event

  register_proxy :wisebed_reservation


  property :start_time, access: :init_only
  property :end_time,   access: :init_only
  property :nodeUrns,   access: :init_only

  # ...
  # TODO: think about useful properties:
  #   - a list of sub resources is available as "children"
  #   - e.g. :nodeUrns as topic identifier.


  hook :before_ready do |reservation|
    @reservation_event = reservation.opts[:reservationEvent]
    # create the "all node group"
    nodeUrns = reservation.opts[:nodeUrns]
    reservation.create(:wisebed_node, {uid: Utils::UIDHelper::node_group_uid(@reservation_event, nodeUrns), nodeUrns: nodeUrns})
    # create the "single node groups"
    nodeUrns.each {|nodeUrn|
      set = Set.new(nodeUrn)
      reservation.create(:wisebed_node, {uid: Utils::UIDHelper::node_group_uid(@reservation_event, set), nodeUrns: set})
    }
  end

  hook :before_release do |reservation|
    debug "#{reservation.uid} is now released"
  end

end


