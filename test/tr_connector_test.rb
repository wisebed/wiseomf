require 'yaml'
CONFIG = YAML.load_file '../config.yml'

# requiring WiseOMF classes and helpers:
# Need omf_rc gem to be required, this will load all dependencies

require 'omf_rc'
require 'protocol_buffers'

require 'test/unit'
require_relative '../lib/tr_connector'

require_relative '../protobuf/internal-messages.pb'
require_relative '../protobuf/external-plugin-messages.pb'
require_relative '../protobuf/iwsn-messages.pb'

class TRConnectorTest < Test::Unit::TestCase
  include De::Uniluebeck::Itm::Tr::Iwsn::Messages

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    puts "Starting test"
    TRConnector.instance.start
    sleep(1)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_upstream
    req = Request.new
    req.type = Request::Type::ARE_NODES_ALIVE
    req.areNodesAliveRequest = AreNodesAliveRequest.new
    req.areNodesAliveRequest.nodeUrns << 'urn:uzl1:0x123'
    req.requestId = 42

    TRConnector.instance.pack_and_send_request({request: req})

    sleep(5)
  end
end