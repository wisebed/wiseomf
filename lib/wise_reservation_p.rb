require_relative '../protobuf/iwsn-messages.pb'
require_relative '../protobuf/internal-messages.pb'
require_relative '../protobuf/external-plugin-messages.pb'
module OmfRc::ResourceProxy::WisebedReservationProxy
  include OmfRc::ResourceProxyDSL
  include De::Uniluebeck::Itm::Tr::Iwsn::Messages

  register_proxy :wisebed_reservation

  property :start_time
  property :end_time
  property :key # TODO or is there a pre defined field uid? (no read, no set)
  property :username
  property :nodeUrns

  # ...
  # TODO: think about useful properties:
  #   - a list of sub resources is available as "children"
  #   - knowledge about available resource types  (e.g. list of reserved node types from the TR DeviceDB)
  #   - reservation id from the  REST API
  #   - or secretReservationKeyBase64
end


