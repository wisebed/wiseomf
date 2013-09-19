module OmfRc::ResourceProxy::WisebedReservationProxy
  include OmfRc::ResourceProxyDSL

  register_proxy :wisebed_reservation

  property :start_time
  property :end_time
  # ...
end


