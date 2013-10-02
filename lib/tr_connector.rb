require 'socket'
require 'event_bus'
require 'set'
require 'logger'
require_relative '../protobuf/internal-messages.pb'
require_relative '../protobuf/external-plugin-messages.pb'
require_relative '../protobuf/iwsn-messages.pb'
require_relative '../resources/event_type'

# the TRConnector handles the tcp socket connection to the testbed runtime

class TRConnector
  @@log = Logger.new(STDOUT)
  @@log.level = Logger::DEBUG
  include Singleton
  include De::Uniluebeck::Itm::Tr::Iwsn::Messages
  @thread
  @socket
  @abort = false


  def initialize
    EventBus.subscribe(Events::DOWN_FLASH_IMAGE, self, :on_flash_image)
    EventBus.subscribe(Events::DOWN_MESSAGE, self, :on_message)
    EventBus.subscribe(Events::DOWN_RESET, self, :on_nodes_reset)
    EventBus.subscribe(Events::DOWN_ARE_NODES_CONNECTED, self, :on_nodes_connected_request)
    EventBus.subscribe(Events::DOWN_ARE_NODES_ALIVE, self, :on_nodes_alive_request)
  end

  def start
    @thread = Thread.new {
      while !@abort
        begin
          info "All Sockets:  #{TCPSocket.gethostbyname(CONFIG[:trhost])}"
          @socket = TCPSocket.new(CONFIG[:trhost], CONFIG[:trport])
          info "Connected to #{CONFIG[:trhost]} on #{CONFIG[:trport]}."
          break
        rescue
          warn "Can't connect to testbed runtime. Sleeping for 10 seconds"
          sleep 10
        end
      end

      while !@abort
        begin
          lengthField = @socket.read(4)
          length = lengthField.unpack('N').first
          data = @socket.read(length)
          epm = ExternalPluginMessage.parse(data)
          #info "parse success"
          case epm.type
            when ExternalPluginMessage::Type::INTERNAL_MESSAGE
              self.handleInternalMessage(epm)
            when ExternalPluginMessage::Type::IWSN_MESSAGE
              self.handleIwsnMessage(epm)
          end
        rescue Exception => e
          error e
        end
      end
      info ">> LOOP End"

      socket.close

    }


  end

  def write(message)
    @socket.puts(message) unless @socket.nil?
  end

  # Event Bus Events (Downstream)

  def on_flash_image(payload)
    pack_and_send_request(payload)
  end

  def on_message(payload)
    pack_and_send_request(payload)
  end

  def on_nodes_reset(payload)
    pack_and_send_request(payload)
  end

  def on_nodes_connected_request(payload)
    pack_and_send_request(payload)
  end

  def on_nodes_alive_request(payload)
    pack_and_send_request(payload)
  end

  def pack_request(payload)
    message = Message.new
    message.type = Message::Type::REQUEST
    message.request = payload[:request]

    external = ExternalPluginMessage.new
    external.type = ExternalPluginMessage::Type::IWSN_MESSAGE
    external.iwsn_message = message

    str = external.serialize_to_string

    @@log.debug "External Message: #{external.to_hash}"
    @@log.debug "Bytes: #{str.bytes}"
    @@log.debug "Bytesize: #{str.bytesize}"

    length = [str.bytesize].pack('N')
    return length, str
  end

  def pack_and_send_request(payload)
    length, msg = pack_request(payload)
    unless @socket.nil?
      @socket.send(length, 0)
      @socket.send(msg, 0)
    else
      @@log.error('Can\'t write to socket.')
    end
  end

  # Testbed Events (Upstream)

  def handleInternalMessage(epm)
    #info "Internal Message: #{epm.internal_message.to_s}"

    case epm.internal_message.type
      when InternalMessage::Type::RESERVATION_EVENT
        re = epm.internal_message.reservationEvent
        case re.type
          when ReservationEvent::Type::STARTED
            EventBus.publish(Events::RESERVATION_STARTED, event: re)
          when ReservationEvent::Type::ENDED
            EventBus.publish(Events::RESERVATION_ENDED, event: re)
        end

      # no other cases atm
    end

  end

  def handleIwsnMessage(epm)
    #info "Iwsn Message: #{epm.iwsn_message.to_s}"
    message = epm.iwsn_message

    case message.type
      when Message::Type::EVENT
        handleIwsnEvent(message.event)
      when Message::Type::RESPONSE
        EventBus.publish(Events::IWSN_RESPONSE, event: message.response, requestId: message.response.requestId, nodeUrns: Set.new([message.response.nodeUrn]))
      when Message::Type::PROGRESS
        EventBus.publish(Events::IWSN_PROGRESS, event: message.progress, requestId: message.progress.requestId, nodeUrns: Set.new([message.progress.nodeUrn]))
      when Message::Type::GET_CHANNELPIPELINES_RESPONSE
        EventBus.publish(Events::IWSN_GET_CHANNEL_PIPELINES_RESPONSE, event: message.getChannelPipelinesResponse, requestId: message.getChannelPipelinesResponse.requestId)

    end
  end

  def handleIwsnEvent(event)
    case event.type
      when Event::Type::UPSTREAM_MESSAGE
        EventBus.publish(Events::IWSN_UPSTREAM_MESSAGE, event: event.upstreamMessageEvent, eventId: event.eventId, nodeUrns: Set.new([event.upstreamMessageEvent.sourceNodeUrn]))
      when Event::Type::DEVICES_DETACHED
        EventBus.publish(Events::IWSN_DEVICES_DETACHED, event: event.devicesDetachedEvent, eventId: event.eventId, nodeUrns: Set.new(event.devicesDetachedEvent.nodeUrns))
      when Event::Type::DEVICES_ATTACHED
        EventBus.publish(Events::IWSN_DEVICES_ATTACHED, event: event.devicesAttachedEvent, eventId: event.eventId, nodeUrns: Set.new(event.devicesAttachedEvent.nodeUrns))
      when Event::Type::NOTIFICATION
        unless event.notificationEvent.nodeUrn.nil?
          EventBus.publish(Events::IWSN_NOTIFICATION, event: event.notificationEvent, eventId: event.eventId, nodeUrns: Set.new([event.notificationEvent.nodeUrn]))
        else
          EventBus.publish(Events::IWSN_NOTIFICATION, event: event.notificationEvent, eventId: event.eventId)
        end
    end
  end

  def abort
    if !@abort
      @abort = true
      info 'Aborting TRConnector'
      @thread.kill
      @socket.close unless @socket.nil?
    end
  end
end