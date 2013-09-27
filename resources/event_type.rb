  module Events
    # Reservation Events
    RESERVATION_STARTED = :reservation_started_event
    RESERVATION_ENDED = :reservation_ended_event

    # IWSN Events
    IWSN_EVENT = :iwsn_event
    IWSN_EVENT_ACK = :iwsn_event_ack

    # Single Node Events
    IWSN_REQUEST = :iwsn_request
    IWSN_RESPONSE = :iwsn_single_node_response
    IWSN_PROGRESS = :iwsn_single_node_progress
    IWSN_GET_CHANNEL_PIPELINES_RESPONSE = :iwsn_channel_pipelines_response
  end