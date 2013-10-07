
defApplication('wiseomf_test') {|app|
  debug "Defining app #{app}"
  app.description = 'Simple omf rc test experiment description'
  app.defProperty('reservation_id', 'The wisebed reservation id (the reservation topic)', '--id', {type: :string})
}

defGroup('ReservationGroup', 'W3sibm9kZVVyblByZWZpeCI6InVybjp3aXNlYmVkOnV6bDEiLCJ1c2VybmFt
ZSI6InVzZXIiLCJrZXkiOiIxIn0seyJub2RlVXJuUHJlZml4IjoidXJuOndp
c2ViZWQ6dXpsMiIsInVzZXJuYW1lIjoidXNlciIsImtleSI6IjIifV0=
') { |g|
  debug "Defining group #{g}"
  g.addApplication('wiseomf_test') {|app| info "Adding #{app}"}
}

onEvent(:ALL_UP) {|event|
  info 'Starting WiseOMF test experiment'
  allGroups.startApplications
}

onEvent(:ALL_INTERFACE_UP) {|event|
  info 'Received CREATION OK'
}

