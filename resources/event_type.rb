  module Events
    # Reservation Events
    RESERVATION_STARTED = :reservation_started_event
    RESERVATION_ENDED = :reservation_ended_event
    RESERVATION_CANCELLED = :reservation_cancelled_event

    # IWSN Events
    IWSN_UPSTREAM_MESSAGE = :iwsn_upstream_message
    IWSN_DEVICES_ATTACHED = :iwsn_device_attached
    IWSN_DEVICES_DETACHED = :iwsn_device_detached
    IWSN_NOTIFICATION = :iwsn_notification

    # Single Node Events
    IWSN_RESPONSE = :iwsn_single_node_response
    IWSN_PROGRESS = :iwsn_single_node_progress
    IWSN_GET_CHANNEL_PIPELINES_RESPONSE = :iwsn_channel_pipelines_response

    # Request Events

    # Downstream Events
    DOWN_FLASH_IMAGE = :down_flash_image
    DOWN_ARE_NODES_ALIVE = :down_are_nodes_alive
    DOWN_ARE_NODES_CONNECTED = :down_are_nodes_connected
    DOWN_RESET = :down_reset
    DOWN_MESSAGE = :down_message
  end