# This file contains a brief example of an experiment with a couple of nodes in the wisebed.
#

require 'yaml'
require 'protocol_buffers'
require 'base64'


# requiring the helper classes for experimenting with the testbed.
# the helper capsulates some omf calls and provides the ability to provide callbacks for requests and configure calls.
require_relative 'ec/wisebed_client'


# your testbed reservation with the urn prefixes and the reservation keys as well as the nodeUrns is stored in a yaml file.
# This configuration is needed for the initial setup and a proper connection to the omf rc.
reservation = YAML.load_file('./ec/reservation_definition.yml')

# Initializing the reservation manager (it's a factory!)
WisebedClient::ReservationManager.init(reservation, reservation[:nodeUrns])

info 'Starting Setup!'


# Register a default callback for the group which contains all nodes in your reservation (the "allNodesGroup").
# The default callback is called for every message comming from the omf_rc for wich there isn't another callback set.
# The received omf message is offered to the callback.
WisebedClient::ReservationManager.allNodesGroup.default_callback = lambda { |msg|
  info "Default Callback: #{msg.to_yaml}"
}

# The initial setup is finished and all nodes are ready for the experiment:
onEvent :ALL_NODES_UP do
  info 'ALL_NODES_UP'

  # The allNodesGroup is asked whether the nodes are connected or not.
  # The callback receives a set of properties containing an array of responses (on for each node in the group)
  # Every response contains a statusCode which is 1 if the node is connected. Furthermore every response contains the appropriate nodeUrn.
  WisebedClient::ReservationManager.allNodesGroup.connected { |properties|
    warn "Got connected callback: #{props.to_yaml}"

    # Testing whether all nodes are connected or not:
    if properties.responses.all? { |response| response.statusCode == 1 }

      # Reading a binary image to flash on the nodes:
      flash_image = File.read('./ec/uart_echo.jn5148.bin')

      info "All nodes are connected"

      # Install the image on all nodes.
      # NOTICE: You have to send the image base64 encoded to prevent compatibility issues with the xml message format.
      #
      # The callback is called every time a node in the group sends a progress message (statusCode = 0..100, type: progress)
      # Furthermore, if all nodes have completed the flashing progress a response is send (type: response), which contains the status of every node in the group.
      WisebedClient::ReservationManager.allNodesGroup.set_image(Base64.encode64(flash_image)) { |properties|
        info "Flashing...\n#{properties.to_yaml}"

        # TODO check for type and perform different operations
        # TODO call the reset request.
      }
    else
      warn "A Node is not connected. Can't flash the entire group: #{properties.responses.to_yaml}"
    end
  }
end

