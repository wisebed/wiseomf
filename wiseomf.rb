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


switch = true

Signal.trap('SIGINT') do
  switch = false
end

while switch do
  sleep 1
end