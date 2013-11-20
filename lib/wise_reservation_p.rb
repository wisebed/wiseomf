require 'event_bus'
require 'omf_rc'
require 'set'
require 'wise_omf/server'
require 'yaml'

module OmfRc::ResourceProxy::WisebedReservation
  include OmfRc::ResourceProxyDSL
  include De::Uniluebeck::Itm::Tr::Iwsn::Messages

  attr_accessor :reservation_event

  @reservation_event

  register_proxy :wisebed_reservation


  property :start_time, access: :init_only
  property :end_time, access: :init_only
  property :nodeUrns, access: :init_only

  hook :before_ready do |reservation|
    debug 'before_ready'
    reservation.reservation_event = reservation.opts.reservationEvent
    # create the "all node group"
    nodeUrns = reservation.opts.nodeUrns
    child_uid = WiseOMFUtils::UIDHelper::node_group_uid(reservation.reservation_event, nodeUrns)

    reservation.create(:wisebed_node, {uid: child_uid, urns: nodeUrns})
    ## create the "single node groups"
    nodeUrns.each { |nodeUrn|
      set = Set.new([nodeUrn])
      cuid = WiseOMFUtils::UIDHelper::node_group_uid(reservation.reservation_event, set)
      reservation.create(:wisebed_node, {uid: cuid, urns: set})
    }

  end


  hook :before_release do |reservation|
    debug "#{reservation.uid} is now released"
  end


  ##inherited methods
  def create(type, opts = {}, creation_opts = {}, &creation_callback)
    info "opts = #{opts.to_yaml}"
    info "creation_opts = #{creation_opts.to_yaml}"
    opts.delete(:hrn)
    child_nodeUrns = opts[:urns]
    if child_nodeUrns.all? { |v| self.opts.nodeUrns.include?(v) }
      debug "Going to create group for #{child_nodeUrns.to_yaml}."
      opts[:uid] = child_uid unless opts[:uid]
      proxy = super(type, opts, creation_opts, &creation_callback)
      return proxy
    else
      warn "No permission to create group for #{child_nodeUrns.to_yaml}"
      return nil
    end
  end

end


