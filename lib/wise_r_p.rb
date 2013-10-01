# By using default namespace OmfRc::ResourceProxy, the module defined could be loaded automatically.
#
require 'omf_rc'
require 'event_bus'

require_relative '../protobuf/iwsn-messages.pb'
require_relative '../protobuf/internal-messages.pb'
require_relative '../protobuf/external-plugin-messages.pb'
require_relative '../resources/event_type'

module OmfRc::ResourceProxy::WiseRP
  # Include DSL module, which provides all DSL helper methods
  #
  include OmfRc::ResourceProxyDSL
  include De::Uniluebeck::Itm::Tr::Iwsn::Messages
  # DSL method register_proxy will register this module definition,
  # where :wiserp become the :type of the proxy.
  #
  register_proxy :wisebed_old_node, :create_by => :wisebed_reservation


  # DSL method property will define proxy's internal properties,
  # and you can provide initial default value.
  #
  property :node_type, :default => 'isense48'
  property :position, :default => [0,0,0]
  property :nodeUrn, access: :init_only
  property :sensors, :default => [:pir,:acc,:temperature,:light]

  hook :after_initial_configured do |res|
    EventBus.subscribe(Events::IWSN_GET_CHANNEL_PIPELINES_RESPONSE, self, :on_channel_pipelines_response)
    EventBus.subscribe(Events::IWSN_RESPONSE, self, :on_node_response)
    EventBus.subscribe(Events::IWSN_PROGRESS, self, :on_node_progress)
    EventBus.subscribe(Events::IWSN_UPSTREAM_MESSAGE, self, :on_upstream_message)
    EventBus.subscribe(Events::IWSN_DEVICES_ATTACHED, self, :on_devices_attached)
    EventBus.subscribe(Events::IWSN_DEVICES_DETACHED, self, :on_devices_detached)
    EventBus.subscribe(Events::IWSN_NOTIFICATION, self, :on_notification)
  end

  def nodeUrn
    return opts[:nodeUrn]
  end

  def on_node_response(payload)
    return unless payload[:nodeUrn] == self.nodeUrn
    # ---
    response = payload[:event]
    probs = {requestId: response.requestId}

    probs[:response] = response.response if response.response
    probs[:statusCode] = response.statusCode if response.statusCode
    if response.errorMessage
      probs[:reason] = response.errorMessage
      self.inform(:error, probs)
    else
      self.inform_status(probs)
    end
  end

  def on_node_progress(payload)
    return unless payload[:nodeUrn] == self.nodeUrn
    # ---
    progress = payload[:event]
    opts = {requestId: progress.requestId, progressInPercent: progress.progressInPercent}
    if progress.progressInPercent == 100
      self.inform('CREATION.OK'.to_sym, opts)
    else
      self.inform_status(opts)
    end
  end

  def on_upstream_message(payload)
    event = payload[:event]
    return unless event.sourceNodeUrn == self.nodeUrn
    # ---
    opts = {
      ts: event.timestamp,
      event_id: payload[:event_id],
      bytes: event.messageBytes
    }
    self.inform('UPSTREAM'.to_sym, opts)
  end

  def on_devices_attached(payload)
    event = payload[:event]
    return unless event.nodeUrns.include?(self.nodeUrn)
    # ---
    self.inform_status({message: 'Node successfully attached', event_id: payload[:event_id]})
  end

  def on_devices_detached(payload)
    event = payload[:event]
    return unless event.nodeUrns.include?(self.nodeUrn)
    # ---
    self.inform_warn('Connection to node was lost.')
  end

  def on_notification(payload)
    event = payload[:event]
    return unless event.nodeUrn == self.nodeUrn
    # ---
    self.inform_status({message: event.message, event_id: payload[:event_id]})
  end


end


