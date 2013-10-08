require 'yaml'

require_relative 'utils/uid_helper'

reservation = YAML.load_file('./ec/reservation_definition.yml')

defProperty('startTime', Time.now, 'The experiment start time')

defProperty('reservation', reservation, 'Informations about a current reservation (to build the reservation id from)')
defProperty('reservation_id', Utils::UIDHelper.reservation_uid(reservation) , 'The reservation id')
defProperty('nodeUrns', reservation[:nodeUrns], 'An array of node urns which are part of this experiment')

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


defEvent(:START) do |event|
  seconds = Time.now - property.startTime.value
  info "Number of seconds gone by: #{seconds}"
  if seconds > 25
    event.fire
  end
end

info "Defined START Event!"

onEvent(:START) do |event|
  warn "Fire START: #{event}"
  group('AllNodes') {|g|
    warn "Direct nodeUrns response: #{g.resources[type: :wisebed_node].nodeUrns}"
    warn "Direct alive response: #{g.resources[type: :wisebed_node].alive}"
  }

end

onEvent(:ALL_UP) {|event|
  warn 'ALL_UP'
  group('AllNodes') {|g|
    warn "Direct nodeUrns response: #{g.resources[type: :wisebed_node].nodeUrns}"
    warn "Direct alive response: #{g.resources[type: :wisebed_node].alive}"
  }
}


