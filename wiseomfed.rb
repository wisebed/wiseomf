require 'yaml'
require_relative 'utils/uid_helper'

require 'protocol_buffers'

reservation = YAML.load_file('./ec/reservation_definition.yml')

def_property('startTime', Time.now, 'The experiment start time')

def_property('reservation', reservation, 'Informations about a current reservation (to build the reservation id from)')
def_property('reservation_id', Utils::UIDHelper.reservation_uid(reservation) , 'The reservation id')
def_property('nodeUrns', reservation[:nodeUrns], 'An array of node urns which are part of this experiment')

onEvent :ALL_NODES_UP do
  group('AllNodes') {|g|
    #warn "Direct nodeUrns response: #{g.resources.nodeUrns.inspect}"
    #warn "Direct alive response: #{g.resources.alive.inspect}"
    info "Sending alive request to AllNodes"

    g.topic.request([:alive], {}) { |msg|
      warn "Callback: #{msg.properties.alive}"
    }
    g.topic.on_message(:inform_status) { |msg|
      warn "Event: #{msg.to_yaml}"
    }
  }
end

defGroup('ReservationGroup', property.reservation_id.value)
defGroup('AllNodes', Utils::UIDHelper.node_group_uid(reservation, reservation[:nodeUrns]))

reservation[:nodeUrns].each {|urn|
 defGroup(urn, Utils::UIDHelper.node_group_uid(reservation, [urn]))
}
info "All Groups created!"
# TODO groups contain only a single proxy for each node group
#   - how to dynamically create groups with custom topic ids?
#   - how to request property values beside of measurements?
#   - how to interact with the testbed (event based)

