# This file contains a brief example of an experiment with a couple of nodes in the wisebed.
#

require 'yaml'
require 'base64'

# requiring the helper classes for experimenting with the testbed.
# the helper capsulates some omf calls and provides the ability to provide callbacks for requests and configure calls. (gem: wise_omf)
require 'wise_omf/client'


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
  # TODO write the example for creating subgroups
end

