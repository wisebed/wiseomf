require 'event_bus'
require 'omf_rc'
require 'set'
require 'wise_omf/server'

module OmfRc::ResourceProxy::WisebedReservation
  include OmfRc::ResourceProxyDSL
  include De::Uniluebeck::Itm::Tr::Iwsn::Messages

  attr_accessor :reservation_event

  @reservation_event

  register_proxy :wisebed_reservation


  property :start_time, access: :init_only
  property :end_time,   access: :init_only
  property :nodeUrns,   access: :init_only

  hook :before_ready do |reservation|
    debug 'before_ready'
    reservation.reservation_event = reservation.opts.reservationEvent
    # create the "all node group"
    nodeUrns = reservation.opts.nodeUrns
    child_uid = WiseOMFUtils::UIDHelper::node_group_uid(reservation.reservation_event, nodeUrns)

    reservation.create(:wisebed_node, {uid: child_uid, urns: nodeUrns})
    ## create the "single node groups"
    nodeUrns.each {|nodeUrn|
      set = Set.new([nodeUrn])
      cuid = WiseOMFUtils::UIDHelper::node_group_uid(reservation.reservation_event, set)
      reservation.create(:wisebed_node, {uid: cuid, urns: set})
    }

  end


  hook :before_release do |reservation|
    debug "#{reservation.uid} is now released"
  end


  # inherited methods
  #def create(type, opts = {}, creation_opts = {}, &creation_callback)
  #  child_nodeUrns = opts[:urns]
  #  if child_nodeUrns.nil?
  #    error "No nodeUrns provided.."
  #    inform_creation_failed('Please provide a group of node urns to create a group topic for.')
  #    return nil
  #  end
  #  # FIXME validate child node urns
  #  child_uid = WiseOMFUtils::UIDHelper.node_group_uid(self.reservation_event, child_nodeUrns)
  #  if self.child_hash.include? child_uid
  #    debug "The topic '#{child_uid}' already exists."
  #    #inform('CREATION.FAILED'.to_sym, {reason: ' There exists an appropriate group topic for the provided set of nodeUrns.', uid: child_uid})
  #    return self.child_hash[child_uid]
  #  end
  #  info "Going to create group for #{child_nodeUrns}."
  #  opts[:uid] = child_uid if opts[:uid].nil?
  #  proxy = super(type, opts, creation_opts, &creation_callback)
  #  self.child_hash[child_uid] = proxy
  #  return proxy
  #end

end


