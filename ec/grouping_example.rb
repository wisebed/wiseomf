# This file contains a brief example of an experiment with a couple of nodes in the wisebed.
#

require 'yaml'

# requiring the helper classes for experimenting with the testbed.
# the helper capsulates some omf calls and provides the ability to provide callbacks for requests and configure calls. (gem: wise_omf)
require 'wise_omf/client'


# your testbed reservation with the urn prefixes and the reservation keys as well as the nodeUrns is stored in a yaml file.
# This configuration is needed for the initial setup and a proper connection to the omf rc.
reservation = YAML.load_file('./ec/reservation_definition.yml')



# Initializing the reservation manager (it's a factory!)
WiseOMF::Client::ReservationManager.init(reservation, reservation[:nodeUrns])


# Register a default callback for the group which contains all nodes in your reservation (the "allNodesGroup").
# The default callback is called for every message comming from the omf_rc for wich there isn't another callback set.
# The received omf message is offered to the callback.
#WiseOMF::Client::ReservationManager.reservationGroup.default_callback = lambda { |msg|
#  info "Reservation Callback: #{msg.to_yaml}"
#}
WiseOMF::Client::ReservationManager.allNodesGroup.default_callback = lambda { |msg|
  info "Default Callback: #{msg.to_yaml}"
}

# The initial setup is finished and all nodes are ready for the experiment:
onEvent :ALL_NODES_UP do
  WiseOMF::Client::ReservationManager.createGroupForNodes(%w(urn:wisebed:uzl1:0x0002 urn:wisebed:uzl1:0x0003)) { |group|
    group.connected { |properties|
      info "Connected Callback from new group: #{properties.to_yaml}"
      WiseOMF::Client::ReservationManager.done
      OmfEc::Experiment.done
    }
  }
end

