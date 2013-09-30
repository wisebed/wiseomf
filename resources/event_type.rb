  module Events
    # Reservation Events
    RESERVATION_STARTED = :reservation_started_event
    RESERVATION_ENDED = :reservation_ended_event

    # IWSN Events
    IWSN_UPSTREAM_MESSAGE = :iwsn_upstream_message
    IWSN_DEVICES_ATTACHED = :iwsn_device_attached
    IWSN_DEVICES_DETACHED = :iwsn_device_detached
    IWSN_NOTIFICATION = :iwsn_notification

    # Single Node Events
    IWSN_REQUEST = :iwsn_request
    IWSN_RESPONSE = :iwsn_single_node_response
    IWSN_PROGRESS = :iwsn_single_node_progress
    IWSN_GET_CHANNEL_PIPELINES_RESPONSE = :iwsn_channel_pipelines_response

    # Request Events
  end