defProperty('startTime', Time.now, "The experiment start time")
defGroup('Actor', 'actortopic')

defEvent(:MY_FIRST_EVENT) do |event|
  seconds = Time.now - property.startTime.value
  info "Number of seconds gone by: #{seconds}"
  if seconds > 15
    event.fire
  end
end

onEvent(:MY_FIRST_EVENT) do |event|
  info " "
  info "My event has happened!"
  info " "
  Experiment.done
end