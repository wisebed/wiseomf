require 'yaml'
require 'protocol_buffers'
require 'base64'

require_relative 'ec/wisebed_client'

reservation = YAML.load_file('./ec/reservation_definition.yml')
WisebedClient::ReservationManager.init(reservation, reservation[:nodeUrns])

info 'Starting Setup!'

flash_image = File.read('./ec/uart_echo.jn5148.bin')
WisebedClient::ReservationManager.allNodesGroup.default_callback = lambda { |msg|
  info "Default Callback: #{msg.to_yaml}"
}

onEvent :ALL_NODES_UP do
  info 'ALL_NODES_UP'


  WisebedClient::ReservationManager.allNodesGroup.connected { |props|
    warn "Got connected callback: #{props.to_yaml}"
    if props.responses[0].statusCode == 1
      info "Node is alive"
      WisebedClient::ReservationManager.allNodesGroup.set_image(Base64.encode64(flash_image)) { |props|
        info "Flashing...\n#{props.to_yaml}"
        #if props.type.eql? 'response'
        #  OmfEc.el.after(5) {
        #    WisebedClient::ReservationManager.allNodesGroup.set_reset(1) {|resp|
        #      info "Reset Response "
        #    }
        #
        #
        #  }
        #end
      }
    else
      warn "Node is not connected. Can't flash"
    end
  }
end

