# loading config hash from file
require 'yaml'
CONFIG = YAML.load_file './config.yml'

# requiring WiseOMF classes and helpers:
# Need omf_rc gem to be required, this will load all dependencies

require 'omf_rc'
require 'protocol_buffers'

# Including protobuf message definitions
require_relative "protobuf/external-plugin-messages.pb.rb"
require_relative "protobuf/internal-messages.pb.rb"
require_relative "protobuf/iwsn-messages.pb.rb"
include De::Uniluebeck::Itm::Tr::Iwsn::Messages


# Including application logic
require_relative 'lib/tr_connector'
require_relative 'lib/resource_proxy_manager'


runtimeConnector = TRConnector.instance
runtimeConnector.start

ResourceProxyManager.instance

info "WiseOMF started!"

OmfRc::ResourceFactory.load_additional_resource_proxies('./lib')
OmfCommon.init(CONFIG[:env], communication: { url: CONFIG[:xmpp_url] }) do
  debug "OmfCommon.init"
  OmfCommon.comm.on_connected do |comm|
    info "WiseOMF >> Connected to XMPP server"
    comm.on_interrupted {
      puts "WiseOMF >> Interrupt!"
      ResourceProxyManager.instance.handle_interrupt
    }
  end
end