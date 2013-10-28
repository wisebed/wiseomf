require 'omf_rc'
require 'event_bus'
require 'set'
require 'base64'
require 'wise_omf/server'
require_relative '../resources/event_type'
require_relative '../lib/request_handler'

module OmfRc::ResourceProxy::NodeGroupProxy
  # Include DSL module, which provides all DSL helper methods
  #
  include OmfRc::ResourceProxyDSL
  include De::Uniluebeck::Itm::Tr::Iwsn::Messages
  include RequestHandler
  # DSL method register_proxy will register this module definition,
  # where :wiserp become the :type of the proxy.
  #
  register_proxy :wisebed_node, :create_by => :wisebed_reservation

  # Configure and Request Methods (Upstream Events)
  def configure_image(payload)
    debug self.uid
    binary = Base64.decode64(payload.value)
    info "configure_image: value = #{binary}"
    id = payload.requestId
    fir = FlashImagesRequest.new
    fir.nodeUrns = self.nodeUrns
    fir.image = binary
    req = Request.new
    req.requestId = id
    req.type = Request::Type::FLASH_IMAGES
    req.flashImagesRequest = fir
    self.store(id, req)
    EventBus.publish(Events::DOWN_FLASH_IMAGE, request: req)
    return nil
  end

  def configure_alive(requestId)
    debug self.uid
    id = requestId
    info "request_alive #{id}"
    ana = AreNodesAliveRequest.new
    ana.nodeUrns = self.nodeUrns
    req = Request.new
    req.requestId = id
    req.type = Request::Type::ARE_NODES_ALIVE
    req.areNodesAliveRequest = ana
    self.store(id, req)
    EventBus.publish(Events::DOWN_ARE_NODES_ALIVE, request: req)
    return nil
  end

  def configure_connected(requestId)
    debug self.uid
    info "request_connected"
    id = requestId
    anc = AreNodesConnectedRequest.new
    anc.nodeUrns = self.nodeUrns
    req = Request.new
    req.requestId = id
    req.type = Request::Type::ARE_NODES_CONNECTED
    req.areNodesConnectedRequest = anc
    self.store(id, req)
    EventBus.publish(Events::DOWN_ARE_NODES_CONNECTED, request: req)
    return nil
  end

  def configure_reset(payload)
    debug self.uid
    info "configure_reset: value = #{payload.value}"
    # TODO handle value as flag?
    rr = ResetNodesRequest.new
    rr.nodeUrns = self.nodeUrns
    req = Request.new
    req.requestId = payload.requestId
    req.type = Request::Type::RESET_NODES
    req.resetNodesRequest = rr
    self.store(payload.requestId, req)
    EventBus.publish(Events::DOWN_RESET, request: req)
    return nil
  end

  def configure_message(payload)
    debug self.uid
    info "configure_message: value = #{payload.value}"
    id = payload.requestId
    dmr = SendDownstreamMessagesRequest.new
    dmr.targetNodeUrns = self.nodeUrns
    dmr.messageBytes = payload.value
    req = Request.new
    req.requestId = id
    req.type = Request::Type::SEND_DOWNSTREAM_MESSAGES
    req.sendDownstreamMessagesRequest = dmr
    self.store(id, req)
    EventBus.publish(Events::DOWN_MESSAGE, request: req)
    return nil
  end

  def request_nodeUrns
    self.nodeUrns
  end

  # Handle Testbed Responses (Downstream Events)
  def on_channel_pipelines_response(payload)
    return unless handle_response? payload
    id, req, responses, event, nodes = self.extract(payload)
    event.pipelines.each {|pipe|
      responses[pipe.nodeUrn] = [] if responses[pipe.nodeUrn].nil?
      pipe.handlerConfigurations.each{|config|
        responses[pipe.nodeUrn] << config.to_hash
      }
    }
    if self.collection_complete?(id)
      info "Request #{id} is completed. Informing EC."
      self.inform_status(self.build_inform(id, responses, :channel_pipelines_response))
    end
  end

  def on_node_response(payload)
    return unless handle_response? payload
    id, req, responses, event, nodes = self.extract(payload)
    debug self.uid
    info "on_node_response: event = #{event.to_hash}"
    if nodes.count > 1
      error 'SingleNodeResponse has more than one node'
      return
    end
    responses[nodes.first] = {response: event.response, statusCode: event.statusCode, errorMessage: event.errorMessage}
    self.store(id, req, responses)

    if self.collection_complete?(id)
      info "Request #{id} is completed. Informing EC."
      self.inform_status(self.build_inform(id, responses, :response))
    end

  end

  def on_node_progress(payload)
    return unless handle_response? payload
    id, req, responses, event, nodes = self.extract(payload)
    debug self.uid
    info "on_node_progress: event = #{event.to_hash}"
    if nodes.count > 1
      error 'SingleNodeProgress has more than one node'
      return
    end
    self.inform_status({type: :progress, requestId: id, nodeUrns: nodes.to_a, progress: event.progressInPercent})
  end


  # Handle Testbed Events (Downstream Events)

  def on_upstream_message(payload)
    return unless handle_event? payload
    id, req, responses, event, nodes = self.extract(payload)
    info "on_upstream_message: event = #{event.to_hash}"
    intersection = self.nodeUrns & nodes
    info "Node Intersection is #{intersection.to_yaml}"
    # FIXME send message bytes
    hash = {type: :message, nodeUrns: intersection.to_a, timestamp: event.timestamp, payload: event.messageBytes}
    info "status hash: #{hash}"

    self.inform_status(hash)
  end

  def on_devices_attached(payload)
    return unless handle_event? payload
    id, req, responses, event, nodes = self.extract(payload)
    debug self.uid
    info "on_devices_attached: event = #{event.to_hash}"
    intersection = self.nodeUrns & nodes
    self.inform_status({type: :nodes_attached, nodeUrns: intersection.to_a, timestamp: event.timestamp, message: 'Some nodes in this group where attached.'})
  end

  def on_devices_detached(payload)
    return unless handle_event? payload
    id, req, responses, event, nodes = self.extract(payload)
    debug self.uid
    info "on_devices_detached: event = #{event.to_hash}"
    intersection = self.nodeUrns & nodes
    self.inform_warn({type: :nodes_detached, nodeUrns: intersection.to_a, timestamp: event.timestamp, reason: 'Some nodes in this group where detached.'})
  end

  def on_notification(payload)
    return unless handle_event? payload
    id, req, responses, event, nodes = self.extract(payload)
    info "on_notification: event = #{event.to_hash}"
    intersection = self.nodeUrns & nodes
    self.inform_status({type: :notification, nodeUrns: intersection.to_a, timestamp: event.timestamp, message: event.message})
  end

  # Hooks
  hook :before_ready do |ngp|
    debug "before_ready: #{ngp}"
    ngp.nodeUrns = Set.new(ngp.opts.urns)
    ngp.cache = LRUCache.new(ttl: 30.minutes)
    # Testbed Responses
    EventBus.subscribe(Events::IWSN_GET_CHANNEL_PIPELINES_RESPONSE, ngp, :on_channel_pipelines_response)
    EventBus.subscribe(Events::IWSN_RESPONSE, ngp, :on_node_response)
    EventBus.subscribe(Events::IWSN_PROGRESS, ngp, :on_node_progress)

    # Testbed Events
    EventBus.subscribe(Events::IWSN_UPSTREAM_MESSAGE, ngp, :on_upstream_message)
    EventBus.subscribe(Events::IWSN_DEVICES_ATTACHED, ngp, :on_devices_attached)
    EventBus.subscribe(Events::IWSN_DEVICES_DETACHED, ngp, :on_devices_detached)
    EventBus.subscribe(Events::IWSN_NOTIFICATION, ngp, :on_notification)
    info "Opts: #{ngp.opts}"
    info "Nodes in Group: #{ngp.nodeUrns.to_a}"
  end

end