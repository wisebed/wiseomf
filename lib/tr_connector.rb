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

  def start
    @thread = Thread.new {
      loop {
        begin
          info "All Sockets:  #{TCPSocket.gethostbyname(CONFIG[:trhost])}"
          @socket = TCPSocket.new(CONFIG[:trhost], CONFIG[:trport])
          info "Connected to #{CONFIG[:trhost]} on #{CONFIG[:trport]}."
            break
        rescue
          warn "Can't connect to testbed runtime. Sleeping for 10 seconds"
          sleep 10
        end
      }

      loop {
          info " >> LOOP Begin"
          # FIXME: Solution for the length problem?
          epmLine = ''
          loop {
            epmLine << @socket.read(1)
            print epmLine
            #epm = ExternalPluginMessage.parse(epmLine)
            #if epm
            #  info "EPM detected"
            #  break
            #end
          }
          epm = ExternalPluginMessage.parse(@socket)
          info "Parsed #{epm}"

          #info "After parse"
          #info "EPM: #{epm}"
          #info "Got #{epmLine}"
          #epm = ExternalPluginMessage.parse(epmLine)
          #puts "Valid: #{epm.nil?}"

      #  re = ReservationEvent.new
      #info "Test 3"
      #  re.type = ReservationEvent::Type::STARTED
      #  puts "2"
      #  re.key = "1234"
      #  re.username = "flkdsjklfsd"
      #  re.nodeUrns = %w{aasd asdaslkj asdalks askldaskl}
      #  re.interval_start = "12345"
      #  re.interval_end = "1234556"
      #
      #  im = InternalMessage.new
      #  im.type = InternalMessage::Type::RESERVATION_EVENT
      #  im.reservationEvent = re
      #
      #
      #  epm = ExternalPluginMessage.new
      #  epm.internal_message = im
      #  info epm

        case epm.type
          when ExternalPluginMessage::Type::INTERNAL_MESSAGE
            self.handleInternalMessage(epm)
          when ExternalPluginMessage::Type::IWSN_MESSAGE
            self.handleIwsnMessage(epm)
        end
        sleep 60
        # TODO convert protobuf messages and pass them to the event listeners
      }

      socket.close

    }


  end

  def handleInternalMessage(epm)
      info "Internal Message: #{epm.internal_message}"

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
    info "Iwsn Message: #{epm.iwsn_message}"
    # TODO handle the Iwsn Message as needed.
  end

end