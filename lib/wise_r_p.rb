# Need omf_rc gem to be required, will load all dependencies
require 'omf_rc'

# By using default namespace OmfRc::ResourceProxy, the module defined could be loaded automatically.
#
module OmfRc::ResourceProxy::WiseRP
  # Include DSL module, which provides all DSL helper methods
  #
  include OmfRc::ResourceProxyDSL

  # DSL method register_proxy will register this module definition,
  # where :wiserp become the :type of the proxy.
  #
  register_proxy :wiserp


  # DSL method property will define proxy's internal properties,
  # and you can provide initial default value.
  #
  property :node_type, :default => "isense39 (default)"
  property :position, :default => [0,0,0]
  property :sensors, :default => [:pir,:acc,:temperature,:light]
end


