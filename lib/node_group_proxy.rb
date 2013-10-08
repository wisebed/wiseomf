require 'omf_rc'
require 'event_bus'
require 'set'

require_relative '../protobuf/iwsn-messages.pb'
require_relative '../protobuf/internal-messages.pb'
require_relative '../protobuf/external-plugin-messages.pb'
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
  def configure_image(value)
    debug self.uid
    info "configure_image: value = #{value}"
    id = self.requestId
    fir = FlashImagesRequest.new
    fir.nodeUrns = self.nodeUrns
    fir.image = value
    req = Request.new
    req.requestId = id
    req.type = Request::Type::FLASH_IMAGES
    req.flashImagesRequest = fir
    self.store(id, req)
    EventBus.publish(Events::DOWN_FLASH_IMAGE, request: req)
    return {requestId: id, message: 'The flash request will be performed. You\'ll recive progress notifications.'}
  end

  def request_alive
    debug self.uid
    info "request_alive"
    id = self.requestId
    ana = AreNodesAliveRequest.new
    ana.nodeUrns = self.nodeUrns
    req = Request.new
    req.requestId = id
    req.type = Request::Type::ARE_NODES_ALIVE
    req.areNodesAliveRequest = ana
    self.store(id, req)
    EventBus.publish(Events::DOWN_ARE_NODES_ALIVE, request: req)
    return {requestId: id, message: 'Your request will be performed.'}
  end

  def request_connected
    debug self.uid
    info "request_connected"
    id = self.requestId
    anc = AreNodesConnectedRequest.new
    anc.nodeUrns = self.nodeUrns
    req = Request.new
    req.requestId = id
    req.type = Request::Type::ARE_NODES_CONNECTED
    req.areNodesConnectedRequest = anc
    self.store(id, req)
    EventBus.publish(Events::DOWN_ARE_NODES_CONNECTED, request: req)
    return {requestId: id, message: 'Your request will be performed.'}
  end

  def configure_reset(value)
    debug self.uid
    info "configure_reset: value = #{value}"
    # TODO handle value as flag?
    id = self.requestId
    rr = ResetNodesRequest.new
    rr.nodeUrns = self.nodeUrns
    req = Request.new
    req.requestId = id
    req.type = Request::Type::RESET_NODES
    req.resetNodesRequest = rr
    self.store(id, req)
    EventBus.publish(Events::DOWN_RESET, request: req)
    return {requestId: id, message: 'Your configure command will be performed.'}
  end

  def configure_message(value)
    debug self.uid
    info "configure_message: value = #{value}"
    id = self.requestId
    dmr = SendDownstreamMessagesRequest.new
    dmr.targetNodeUrns = self.nodeUrns
    dmr.messageBytes = value
    req = Request.new
    req.requestId = id
    req.type = Request::Type::SEND_DOWNSTREAM_MESSAGES
    req.sendDownstreamMessagesRequest = dmr
    self.store(id, req)
    EventBus.publish(Events::DOWN_MESSAGE, request: req)
    return {requestId: id, message: 'Your configure command will be performed.'}
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
      self.inform('STATUS.CHANNEL_PIPELINES_RESPONSE'.to_sym, self.build_inform(id, responses))
    end
  end

  def on_node_response(payload)
    return unless handle_response? payload
    id, req, responses, event, nodes = self.extract(payload)
    debug self.uid
    info "on_node_response: event = #{event}"
    if nodes.count > 1
      error 'SingleNodeResponse has more than one node'
      return
    end
    responses[nodes.first] = {response: event.response, statusCode: event.statusCode, errorMessage: event.errorMessage}
    self.store(id, req, responses)

    if self.collection_complete?(id)
      info "Request #{id} is completed. Informing EC."
      self.inform('STATUS.RESPONSE'.to_sym, self.build_inform(id, responses))
    end

  end

  def on_node_progress(payload)
    return unless handle_response? payload
    id, req, responses, event, nodes = self.extract(payload)
    debug self.uid
    info "on_node_progress: event = #{event}"
    if nodes.count > 1
      error 'SingleNodeProgress has more than one node'
      return
    end
    self.inform('STATUS.PROGRESS'.to_sym, {requestId: id, nodeUrns: nodes, progress: event.progressInPercent})
  end


  # Handle Testbed Events (Downstream Events)

  def on_upstream_message(payload)
    return unless handle_event? payload
    id, req, responses, event, nodes = self.extract(payload)
    info "on_upstream_message: event = #{event}"
    intersection = self.nodeUrns & nodes
    self.inform('STATUS.MESSAGE'.to_sym, {nodeUrns: intersection, timestamp: event.timestamp, message: event.messageBytes})
  end

  def on_devices_attached(payload)
    return unless handle_event? payload
    id, req, responses, event, nodes = self.extract(payload)
    debug self.uid
    info "on_devices_attached: event = #{event}"
    intersection = self.nodeUrns & nodes
    self.inform('STATUS.NODES_ATTACHED'.to_sym, {nodeUrns: intersection, timestamp: event.timestamp, message: 'Some nodes in this group where attached.'})
  end

  def on_devices_detached(payload)
    return unless handle_event? payload
    id, req, responses, event, nodes = self.extract(payload)
    debug self.uid
    info "on_devices_detached: event = #{event}"
    intersection = self.nodeUrns & nodes
    self.inform('WARN.NODES_DETACHED'.to_sym, {nodeUrns: intersection, timestamp: event.timestamp, reason: 'Some nodes in this group where detached.'})
  end

  def on_notification(payload)
    return unless handle_event? payload
    id, req, responses, event, nodes = self.extract(payload)
    info "on_notification: event = #{event}"
    intersection = self.nodeUrns & nodes
    self.inform('STATUS.NOTIFICATION'.to_sym, {nodeUrns: intersection, timestamp: event.timestamp, message: event.message})
  end

  # Hooks
  hook :before_ready do |ngp|
    debug "before_ready: #{ngp}"
    ngp.nodeUrns = ngp.opts.nodeUrns.to_set
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
  end

end