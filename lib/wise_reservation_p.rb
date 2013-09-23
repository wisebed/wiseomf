
module OmfRc::ResourceProxy::WisebedReservationProxy
  include OmfRc::ResourceProxyDSL

  register_proxy :wisebed_reservation

  property :start_time
  property :end_time

  # ...
  # TODO: think about useful properties:
  #   - a list of subnodes might be useful.
  #   - knowledge about available resource types  (e.g. list of reserved node types from the TR DeviceDB)
  #   - reservation id from the  REST API
end


