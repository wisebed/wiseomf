require_relative '../protobuf/iwsn-messages.pb'
require_relative '../protobuf/internal-messages.pb'
require_relative '../protobuf/external-plugin-messages.pb'
module OmfRc::ResourceProxy::WisebedReservation
  include OmfRc::ResourceProxyDSL
  include De::Uniluebeck::Itm::Tr::Iwsn::Messages

  register_proxy :wisebed_reservation

  property :start_time, access: :init_only
  property :end_time,   access: :init_only
  property :username,   access: :init_only
  property :nodeUrns,   access: :init_only

  # ...
  # TODO: think about useful properties:
  #   - a list of sub resources is available as "children"
  #   - e.g. :nodeUrns as topic identifier.




  hook :before_release do |res|
    # TODO: release children? (e.g. node proxies)
    logger.debug "#{res.uid} is now released"
  end
end


