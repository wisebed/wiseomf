require 'socket'
require 'event_bus'
require_relative '../protobuf/internal-messages.pb'
require_relative '../protobuf/external-plugin-messages.pb'
require_relative '../protobuf/iwsn-messages.pb'
require_relative '../resources/event_type'

# the TRConnector handles the tcp socket connection to the testbed runtime

class TRConnector
  include Singleton
  include De::Uniluebeck::Itm::Tr::Iwsn::Messages
  @thread
  @socket
  @abort = false


  def initialize

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
        EventBus.publish(Events::IWSN_EVENT, event: message.event)
      when Message::Type::EVENT_ACK
        EventBus.publish(Events::IWSN_EVENT_ACK, event: message.eventAck)
      when Message::Type::RESPONSE
        EventBus.publish(Events::IWSN_RESPONSE, event: message.response)
      when Message::Type::REQUEST
        EventBus.publish(Events::IWSN_REQUEST, event: message.request)
      when Message::Type::PROGRESS
        EventBus.publish(Events::IWSN_PROGRESS, event: message.progress)
      when Message::Type::GET_CHANNELPIPELINES_RESPONSE
        EventBus.publish(Events::IWSN_GET_CHANNEL_PIPELINES_RESPONSE, event: message.getChannelPipelinesResponse)

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